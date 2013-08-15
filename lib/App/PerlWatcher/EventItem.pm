package App::PerlWatcher::EventItem;
# ABSTRACT: Used to store event items (file lines, rss news headers and so on).

use 5.12.0;
use strict;
use warnings;

use Moo;

=attr content

Contains string description of particular event

=cut
has 'content'   => ( is => 'ro', required => 1 );

=attr content

The timestamp of event item. By default it is the current time.

=cut
has 'timestamp' => ( is => 'ro', default => sub{ time; } );

1;
