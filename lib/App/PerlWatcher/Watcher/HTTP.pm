package App::PerlWatcher::Watcher::HTTP;
# ABSTRACT: The base role for watching external events via HTTP

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::EventItem;
use AnyEvent::HTTP;
use Carp;
use Function::Parameters qw(:strict);
use List::MoreUtils qw/any/;
use Moo::Role;
use Smart::Comments -ENV;
use URI;

=attr url

The subclass should provide the watched URL

=cut
requires 'url';

=method process_http_response

The subclass should provide the process_http_response($body, $headers) method
which is been called only on successfull responce (http code = 200)

=cut

requires 'process_http_response';

with qw/App::PerlWatcher::Watcher/;

=attr frequency

The frequency of poll in seconds

=cut

has 'frequency'         => ( is => 'ro', default => sub { 60; } );

# for internal use only. No docs.
has 'uri'               => ( is => 'lazy');

=attr timeout

The http transaction timeout. Default value: 5 seconds

=cut

has 'timeout'           => ( is => 'lazy');

=attr

The watcher title

=cut

has 'title'             => ( is => 'lazy');

=attr watcher_callback

The callback, which will be called with status object

=cut

has 'watcher_callback'  => ( is => 'lazy');

method _build_uri {
    return URI->new($self->url);
}

method _build_timeout {
    $self->config->{timeout} // $self->engine_config->{defaults}->{timeout} // 5;
}

method _build_title {
    $self->uri->host;
}

method _build_watcher_callback {
    my $uri = $self->uri;
    my $watcher = sub {
        $self->poll_callback->($self);
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
                    $self->interpret_result(
                        0,
                        sub {
                            my $status = shift;
                            $self->_invoke_callback(
                                $self->callback,
                                $status
                            );
                        }
                    );
                }
            }
        );
    };
    return $watcher;
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
    my $self = shift;
    return "HTTP [" . $self->title . "]";
}

# private API

# intendent to be overriden in descendants
method _invoke_callback($callback, $status) {
    $callback->($status);
}

1;
