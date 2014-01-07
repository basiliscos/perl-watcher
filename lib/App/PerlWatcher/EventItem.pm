package App::PerlWatcher::EventItem;
{
  $App::PerlWatcher::EventItem::VERSION = '0.20';
}
# ABSTRACT: Used to store event items (file lines, rss news headers and so on).

use 5.12.0;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Str Num/;

with qw/App::PerlWatcher::Memorizable/;


has 'content' => (is => 'rw', isa => Str, required => 1);


has 'timestamp' => (
    is => 'rw',
    isa => Num,
    default => sub { time }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::EventItem - Used to store event items (file lines, rss news headers and so on).

=head1 VERSION

version 0.20

=head1 ATTRIBUTES

=head2 content

Contains string description of particular event. Required.

=head2 timestamp

The timestamp of event item. By default it is the current time.

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
