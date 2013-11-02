package App::PerlWatcher::Watcher::Rss;
{
  $App::PerlWatcher::Watcher::Rss::VERSION = '0.16_4';
}
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
    $self->interpret_result(1, $self->callback,$self->last_items );
}

sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $status->items($self->last_items);
    $callback->($status);
}


1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Watcher::Rss - Watches RSS feed and returns last news headers as clickable Eventitems.

=head1 VERSION

version 0.16_4

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

=head1 ATTRIBUTES

=head2 url

The RSS feed URL

=head2 items_number

The number of news items to be displayed

=head2 last_items

Last fetched rss items.

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
