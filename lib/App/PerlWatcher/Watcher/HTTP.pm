package App::PerlWatcher::Watcher::HTTP;
{
  $App::PerlWatcher::Watcher::HTTP::VERSION = '0.20';
}
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

requires 'url';


requires 'process_http_response';

with qw/App::PerlWatcher::Watcher/;


has 'frequency'         => ( is => 'ro', default => sub { 60; } );

# for internal use only. No docs.
has 'uri'               => ( is => 'lazy');


has 'timeout'           => ( is => 'lazy');


has 'title'             => ( is => 'lazy');


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

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Watcher::HTTP - The base role for watching external events via HTTP

=head1 VERSION

version 0.20

=head1 ATTRIBUTES

=head2 url

The subclass should provide the watched URL

=head2 frequency

The frequency of poll in seconds

=head2 timeout

The http transaction timeout. Default value: 5 seconds

=head2

The watcher title

=head2 watcher_callback

The callback, which will be called with status object

=head1 METHODS

=head2 process_http_response

The subclass should provide the process_http_response($body, $headers) method
which is been called only on successfull responce (http code = 200)

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
