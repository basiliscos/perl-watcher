package App::PerlWatcher::Watcher::HTTP;
{
  $App::PerlWatcher::Watcher::HTTP::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::EventItem;
use AnyEvent::HTTP;
use Carp;
use Devel::Comments;
use HTTP::Date;
use List::MoreUtils qw/any/;
use Moo::Role;
use URI;


requires 'url';
requires 'process_http_response';

with qw/App::PerlWatcher::Watcher/;

has 'frequency'         => ( is => 'ro', default => sub { 60; } );
has 'uri'               => ( is => 'lazy');
has 'timeout'           => ( is => 'lazy');
has 'title'             => ( is => 'lazy');
has 'watcher_callback'  => ( is => 'lazy');

sub _build_uri {
    return URI->new($_[0]->url);
}

sub _build_timeout {
    $_[0]->config->{timeout} // $_[0]->engine_config->{defaults}->{timeout} // 5;
}

sub _build_title {
    $_[0]->uri->host;
}

sub _build_watcher_callback {
    my $self = shift;
    my $uri = $self->uri;
    my $watcher = sub {
        $self -> {_guard} = http_get (scalar $uri,
            timeout => $self->timeout,
            sub {
                my ($body, $headers) = @_;
                if ($headers -> {Status} =~ /^2/) {
                    # $body
                    $self->process_http_response($body, $headers);
                }
                else{
                    my $reason = $headers -> {Status};
                    # bad thing has happend
                    # $reason
                    # $self
                    $self->_interpret_result(0, sub {
                            my $status = shift;
                            $self->_invoke_callback(
                                $self->callback,
                                $status
                            );
                    });
                }
            }
        );
    };
    return $watcher;
}

sub start {
    my ($self, $callback) = @_;
    $self->callback($callback) if $callback;
    
    $self->{_w} = AnyEvent->timer(
        after    => 0,
        interval => $self->frequency,
        cb       => sub {
            my $watcher_cb = $self->watcher_callback;
            $watcher_cb->() if defined( $self -> {_w} );
        }
    );
}

sub description {
    my $self = shift;
    return "HTTP [" . $self->title . "]";
}

# private API

# intendent to be overriden in descendants
sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $callback->($status);
}

1;
