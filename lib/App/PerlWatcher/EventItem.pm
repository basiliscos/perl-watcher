package App::PerlWatcher::EventItem;
# ABSTRACT: Used to store event items (file lines, rss news headers and so on).

use 5.12.0;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Str Num/;

with qw/App::PerlWatcher::Memorizable/;

=attr content

Contains string description of particular event. Required.

=cut

has 'content' => (is => 'rw', isa => Str, required => 1);

=attr timestamp

The timestamp of event item. By default it is the current time.

=cut

has 'timestamp' => (
    is => 'rw',
    isa => Num,
    default => sub { time }
);

1;
