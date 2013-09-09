package App::PerlWatcher::Watcher::Rss;
# ABSTRACT: Watches RSS feed and returns last news headers as clickable Eventitems.

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

=head1 SYNOPSIS

 # use the following config for Engine:

        {
            class => 'App::PerlWatcher::Watcher::Rss',
            config => {
                url         =>  'http://www.opennet.ru/opennews/opennews_all.rss',
                title       =>  'opennet',
                frequency   => 60,
                timeout     => 10,
                items       =>  5,
                on          => {
                        ok      => { 1  => 'notice' },
                        fail    => { 10 => 'info/max'   },
                },
            },
        },

=cut

=attr url

The RSS feed URL

=cut

has 'url'               => ( is => 'ro', required => 1);

=attr items_number

The number of news items to be displayed

=cut

has 'items_number'      => ( is => 'ro', default => sub { 5; } );

=attr last_items

Last fetched rss items.

=cut

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
    $self->interpret_result(1, $self->callback,$self->last_items );
}

sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $status->items($self->last_items);
    $callback->($status);
}


1;
