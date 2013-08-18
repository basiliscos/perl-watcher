package App::PerlWatcher::Watcher::Ping;
# ABSTRACT: Watches for host availablity via pingig it. Currently only TCP-port ping.

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Socket;
use App::PerlWatcher::Watcher;
use Carp;
use Devel::Comments;
use Moo;

=attr host

The watched host

=cut

has 'host'              => ( is => 'ro', required => 1 );

=attr port

The watched port

=cut

has 'port'              => ( is => 'ro', required => 1 );

=attr frequency

The frequency of ping. By default it is 60 seconds.

=cut

has 'frequency'         => ( is => 'ro', default => sub{ 60; } );

=attr timeout

The ping timeout. Default value: 5 seconds

=cut

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
