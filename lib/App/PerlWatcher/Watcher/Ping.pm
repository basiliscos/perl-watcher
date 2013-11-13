package App::PerlWatcher::Watcher::Ping;
{
  $App::PerlWatcher::Watcher::Ping::VERSION = '0.17_1';
}
# ABSTRACT: Watches for host availablity via pingig it (ICMP) or knoking to it's port (TCP)

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Socket;
use AnyEvent::Util;
use App::PerlWatcher::Watcher;
use Carp;
use Smart::Comments -ENV;
use Moo;
use Net::Ping::External qw(ping);



has 'host'              => ( is => 'ro', required => 1 );


has 'port'              => ( is => 'ro', required => 0 );


has 'frequency'         => ( is => 'ro', default => sub{ 60; } );


has 'timeout'           => ( is => 'lazy');
has 'watcher_callback'  => ( is => 'lazy');

with qw/App::PerlWatcher::Watcher/;

sub _build_timeout {
    $_[0]->config->{timeout} // $_[0]->engine_config->{defaults}->{timeout} // 5;
}

sub _build_watcher_callback {
    my $self = shift;
    $self -> {_watcher} = $self->port
        ? $self->_tcp_watcher_callback
        : $self->_icmp_watcher_callback;
}

sub _icmp_watcher_callback {
    my $self = shift;
    my $host = $self->host;
    my $timeout = $self->timeout;
    return sub {
        fork_call {
            my $alive = ping(host => $host, timeout => $timeout);
            $alive;
        } sub {
            my $success = shift;
            $self->interpret_result( $success, $self->callback);
        };
    }
}

sub _tcp_watcher_callback {
    my $self = shift;
    my ($host, $port ) = ( $self->host, $self->port ); 
    return sub {
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

sub build_watcher_guard {
    my $self = shift;
    return AnyEvent->timer(
        after    => 0,
        interval => $self->frequency,
        cb       => sub {
            $self->watcher_callback->()
              if $self->active;
        }
    );
}

sub description {
    my $self = shift;
    my $description = $self->port
        ? "Knocking at " . $self->host . ":" . $self->port
        : "Ping " . $self->host;
}


1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Watcher::Ping - Watches for host availablity via pingig it (ICMP) or knoking to it's port (TCP)

=head1 VERSION

version 0.17_1

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

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
