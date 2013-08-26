package App::PerlWatcher::Describable;
# ABSTRACT: The base role for providing description for UI

use 5.12.0;
use strict;
use warnings;

use Moo::Role;

=method description

The string description, it means to be provided by developer, e.g. watcher
developer

=cut

requires 'description';

=attr describer

The subroutine, which takes description as an string, and allows
to do with it something funny, e.g. add "location" in label for
weather-watcher:

   describer   => sub { "Weather in Minsk: " . $_[0] },

Default value: sub, which just returns it's value. The describer
means to be provided by user configs.

=cut

has 'describer' => ( is => 'ro', default => sub { return sub { $_[0]; }; }, );


=method describe

Returns the result on passing description via describer.
Means to be used in frontends

=cut

sub describe {
    my $self = shift;
    return $self->describer->($self->description);
}

1;
