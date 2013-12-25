package App::PerlWatcher::EventItem;
# ABSTRACT: Used to store event items (file lines, rss news headers and so on).

use 5.12.0;
use strict;
use warnings;

use Moo;
use App::PerlWatcher::Memory qw /memory_patch/;


with qw/App::PerlWatcher::Memorizable/;

=attr content

Contains string description of particular event. Required.

=cut

memory_patch(__PACKAGE__, 'content');

=attr timestamp

The timestamp of event item. By default it is the current time.

=cut

memory_patch(__PACKAGE__, 'timestamp');

sub BUILD {
    my ($self, $init_args) = @_;
    $self->content($init_args->{content});
    $self->timestamp(time) unless($self->timestamp);
}

1;
