package App::PerlWatcher::Watcher::HTTP;
# ABSTRACT: The base role for watching external events via HTTP

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::EventItem;
use AnyEvent::HTTP;
use Carp;
use Smart::Comments -ENV;
use List::MoreUtils qw/any/;
use Moo::Role;
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
    return "HTTP [" . $self->title . "]";
}

# private API

# intendent to be overriden in descendants
sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $callback->($status);
}

1;
