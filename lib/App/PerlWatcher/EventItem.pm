package App::PerlWatcher::EventItem;
{
  $App::PerlWatcher::EventItem::VERSION = '0.19';
}
# ABSTRACT: Used to store event items (file lines, rss news headers and so on).

use 5.12.0;
use strict;
use warnings;

use Moo;
use App::PerlWatcher::Memory qw /memory_patch/;


with qw/App::PerlWatcher::Memorizable/;


memory_patch(__PACKAGE__, 'content');


memory_patch(__PACKAGE__, 'timestamp');

sub BUILD {
    my ($self, $init_args) = @_;
    $self->content($init_args->{content});
    $self->timestamp(time) unless($self->timestamp);
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::EventItem - Used to store event items (file lines, rss news headers and so on).

=head1 VERSION

version 0.19

=head1 ATTRIBUTES

=head2 content

Contains string description of particular event. Required.

=head2 content

The timestamp of event item. By default it is the current time.

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
