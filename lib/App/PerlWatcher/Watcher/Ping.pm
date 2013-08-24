package App::PerlWatcher::Watcher::Ping;
{
  $App::PerlWatcher::Watcher::Ping::VERSION = '0.14';
}
# ABSTRACT: Watches for host availablity via pingig it. Currently only TCP-port ping.

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Socket;
use App::PerlWatcher::Watcher;
use Carp;
use Devel::Comments;
use Moo;


has 'host'              => ( is => 'ro', required => 1 );


has 'port'              => ( is => 'ro', required => 1 );


has 'frequency'         => ( is => 'ro', default => sub{ 60; } );


has 'timeout'           => ( is => 'lazy');
has 'watcher_callback'  => ( is => 'lazy');

with qw/App::PerlWatcher::Watcher/;

sub _build_timeout {
    $_[0]->config->{timeout} // $_[0]->engine_config->{defaults}->{timeout} // 5;
}

sub _build_watcher_callback {
    my $self = shift;
    my ($host, $port ) = ( $self->host, $self->port ); 
    $self -> {_watcher} = sub {
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

sub start {
    my ($self, $callback) = @_;
    $self->callback($callback) if $callback;
    $self->{_w} = AnyEvent->timer(
        after    => 0,
        interval => $self->frequency,
        cb       => sub {
            $self->watcher_callback->()
              if defined( $self->{_w} );
        }
    );
}

sub description {
    my $self = shift;
    return "Ping " . $self->host . ":" . $self->port;
}


1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Watcher::Ping - Watches for host availablity via pingig it. Currently only TCP-port ping.

=head1 VERSION

version 0.14

=head1 ATTRIBUTES

=head2 host

The watched host

=head2 port

The watched port

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
