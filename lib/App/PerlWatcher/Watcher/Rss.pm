package App::PerlWatcher::Watcher::Rss;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/:levels/;
use App::PerlWatcher::EventItem;
use Carp;
use Devel::Comments;
use HTTP::Date;
use URI;
use XML::Simple;

use base qw(App::PerlWatcher::Watcher::HTTP);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    $config{processor} = \&_process_rss;
    my $self = $class->SUPER::new($engine_config, %config);
    return $self;
}

sub description {
    my $self = shift;
    return "RSS [" . $self->{_title} . "]";
}

sub _process_rss {
    my ($self, $content, $headers) = @_;
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
    $self->_interpret_result(1, $self -> {_callback}, sub { \@news_items; } );
}

1;
