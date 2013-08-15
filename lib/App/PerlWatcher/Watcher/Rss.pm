package App::PerlWatcher::Watcher::Rss;
{
  $App::PerlWatcher::Watcher::Rss::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::EventItem;
use aliased 'App::PerlWatcher::Openable';
use Carp;
use Devel::Comments;
use HTTP::Date;
use Moo;
use XML::Simple;

has 'url'               => ( is => 'ro', required => 1);
has 'items_number'      => ( is => 'ro', default => sub { 5; } );
has 'last_items'        => ( is => 'rw');

with qw/App::PerlWatcher::Watcher::HTTP/;

sub description {
    my $self = shift;
    return "RSS [" . $self->title . "]";
}

sub process_http_response {
    my ($self, $content, $headers) = @_;
    # $content
    my $xml = XMLin( $content );
    my $items = $xml -> {channel} -> {item};
    # $items
    my @top_items = splice @$items, 0, $self->items_number;
    my @news_items = map {
            my $item = App::PerlWatcher::EventItem->new(
                content   => $_->{title},
                timestamp => str2time( $_ -> {pubDate} ),
            );
            my $url = $_->{link};
            Moo::Role->apply_roles_to_object($item, qw/App::PerlWatcher::Openable/);
            $item->url($url);
            $item;
        } @top_items;
    $self->last_items( sub { \@news_items; } );
    $self->_interpret_result(1, $self->callback,$self->last_items );
}

sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $status->items($self->last_items);
    $callback->($status);
}


1;
