package App::PerlWatcher::Watcher::Ping;
{
  $App::PerlWatcher::Watcher::Ping::VERSION = '0.20';
}
# ABSTRACT: Watches for host availablity via pingig it (ICMP) or knoking to it's port (TCP)

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Socket;
use AnyEvent::Util;
use App::PerlWatcher::Watcher;
use Carp;
use Function::Parameters qw(:strict);
use Moo;
use Net::Ping::External qw(ping);
use Smart::Comments -ENV;
use Types::Standard qw/Str Num Maybe CodeRef/;



has 'host'  => ( is => 'ro', required => 1, isa => Str );


has 'port' => ( is => 'ro', required => 0, isa => Maybe[Num]);


has 'frequency' => ( is => 'ro', default => sub{ 60; }, isa => Num );


has 'timeout' => ( is => 'lazy', isa => Num);

has 'watcher_callback'  => ( is => 'lazy', isa => CodeRef);

with qw/App::PerlWatcher::Watcher/;

method _build_timeout {
    $self->config->{timeout} // $self->engine_config->{defaults}->{timeout} // 5;
}

method _build_watcher_callback {
    $self -> {_watcher} = $self->port
        ? $self->_tcp_watcher_callback
        : $self->_icmp_watcher_callback;
}

method _icmp_watcher_callback {
    return sub {
        $self->poll_callback->($self);
        fork_call {
            my $alive = ping(host => $self->host, timeout => $self->timeout);
            $alive;
        } sub {
            my $success = shift;
            $self->interpret_result( $success, $self->callback);
        };
    }
}

method _tcp_watcher_callback {
    my ($host, $port ) = ( $self->host, $self->port );
    return sub {
        $self->poll_callback->($self);
        tcp_connect $host, $port, sub {
            my $success = @_ != 0;
            # $! contains error
            # $host
            # $success
            $self->interpret_result( $success, $self->callback);
          }, sub {

            #connect timeout
            #my ($fh) = @_;

            1;
          };
    };
}

method build_watcher_guard {
    return AnyEvent->timer(
        after    => 0,
        interval => $self->frequency,
        cb       => sub {
            $self->watcher_callback->()
              if $self->active;
        }
    );
}

method description {
    my $description = $self->port
        ? "Knocking at " . $self->host . ":" . $self->port
        : "Ping " . $self->host;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Watcher::Ping - Watches for host availablity via pingig it (ICMP) or knoking to it's port (TCP)

=head1 VERSION

version 0.20

=head1 SYNOPSIS

 # use the following config for Engine:

        {
            class => 'App::PerlWatcher::Watcher::Ping',
            config => {
                host    =>  'google.com',
                frequency   =>  10,
                on => { fail => { 5 => 'alert' } },
            },
        },
 # if the port was defined it does TCP-knock to that port.
 # TCP-knock is required for some hosts, that don't answer to
 # ICMP echo requests, e.g. notorious microsoft.com :)

=head1 ATTRIBUTES

=head2 host

The watched host

=head2 port

The watched port. If the port was specified, then the watcher does
tcp knock to the port; otherwise it does icmp ping of the host

=head2 frequency

The frequency of ping. By default it is 60 seconds.

=head2 timeout

The ping timeout. Default value: 5 seconds

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
