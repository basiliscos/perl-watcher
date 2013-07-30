package App::PerlWatcher::Watcher::Ping;
{
  $App::PerlWatcher::Watcher::Ping::VERSION = '0.11';
}

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

extends qw/App::PerlWatcher::Watcher/;

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
            $self -> _interpret_result( $success, $self->callback);
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
