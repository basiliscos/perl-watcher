package App::PerlWatcher::Watcher::Rss;

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
use XML::Simple;

use base qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    my ( $url, $items_count, $frequency, $timeout, $title ) 
        = @config{ qw/ url items frequency timeout title/ };
        
    croak("url is not defined") unless defined ($url);
    my $uri = URI->new($url);
    
    $items_count //= 5;
    $frequency   //= 60; # once in minute
    $timeout     //= $engine_config -> {defaults} -> {timeout} // 5;
    $title       //= $uri->host;

    my $self = {
        _uri            => $uri,
        _items_count    => $items_count,
        _timeout        => $timeout,
        _frequency      => $frequency,
        _title          => $title,
        _recorded_news  => [],
    };
    bless $self, $class;
    
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
    return "Rss [" . $self->{_title} . "]";
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
                # $headers
                if ($headers -> {Status} =~ /^2/) {
                    $self->_handle_result($body);
                }
                else{
                    ### bad thing has happend
                }
            },
        );
    };
}

sub _handle_result {
    my ($self, $content) = @_;
    # $content
    my $xml = XMLin( $content );
    my $items = $xml -> {channel} -> {item};
    # $items
    my @top_items = splice @$items, 0, $self -> {_items_count};
    my @news_items = map {
            my $item = App::PerlWatcher::EventItem->new( $_ -> {title} );
            $item -> timestamp( str2time( $_ -> {pubDate} ) );
            $item;
        } @top_items;
    $self -> _emit_status(\@news_items);
}

sub _emit_status {
    my ($self, $news_items) = @_;
    my $recorded_items = $self -> {_recorded_news};
    # $news_items
    # $recorded_items

    $self -> {_recorded_news} = $news_items;
    my $status = App::PerlWatcher::Status->new(
        watcher     => $self,
        level       => LEVEL_NOTICE,
        description => sub {  $self->description;  },
        items       => sub { $self -> {_recorded_news}; },
    );
    $self -> {_callback}->($status);
}

1;
