package App::PerlWatcher::Watcher::HTTP;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/:levels/;
use App::PerlWatcher::EventItem;
use AnyEvent::HTTP;
use Carp;
use Devel::Comments;
use HTTP::Date;
use List::MoreUtils qw/any/;
use URI;

use base qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    my ( $url, $items_count, $frequency, $timeout, $title, $processor ) 
        = @config{ qw/ url items frequency timeout title processor/ };
        
    croak("url is not defined") unless defined ($url);
    my $uri = URI->new($url);
    
    $items_count //= 5;
    $frequency   //= 60; # once in minute
    $timeout     //= $engine_config -> {defaults} -> {timeout} // 5;
    $title       //= $uri->host;
    $processor   //= \&_process_http_response;

    my $self = {
        _uri            => $uri,
        _items_count    => $items_count,
        _timeout        => $timeout,
        _frequency      => $frequency,
        _title          => $title,
        _processor      => $processor,
    };
    bless $self, $class;
    
    $self -> _install_thresholds ($engine_config, \%config);
    $self -> _install_watcher;
    
    return $self;
}

sub start {
    my $self = shift;
    $self->{_callback} //= shift;
    $self->{_w} = AnyEvent->timer(
        after    => 0,
        interval => $self->{_frequency},
        cb       => sub {
            $self -> {_watcher}->() if defined( $self -> {_w} );
        }
    );
}

sub description {
    my $self = shift;
    return "HTTP [" . $self->{_title} . "]";
}

# private API

sub _install_watcher {
    my $self = shift;
    my $uri = $self -> {_uri};
    $self -> {_watcher} = sub {
        $self -> {_guard} = http_get (scalar $uri,
            timeout => $self -> {_timeout},
            sub {
                my ($body, $headers) = @_;
                if ($headers -> {Status} =~ /^2/) {
                    $self->{_processor}->($self, $body, $headers);
                }
                else{
                    my $reason = $headers -> {Status};
                    # bad thing has happend
                    # $reason
                    $self->_interpret_result(0, $self -> {_callback});
                }
            }
        );
    };
}

sub _process_http_response {
    my ($self, $body, $headers) = @_;
    ...;
}

1;
