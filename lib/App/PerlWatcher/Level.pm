package App::PerlWatcher::Level;
# ABSTRACT: Represents severity with corresponding metrics e.g. level_info < level_alert

use 5.12.0;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Str Num/;

use overload fallback => 1,
     '0+' => sub { $_[0]->value },
     '""' => sub { $_[0]->description };

=attr value

The numeric value (weight) of level.

=cut

has 'value'  => ( is => 'ro', required => 1, isa => Num);

=attr description

The string desctiption of level

=cut

has 'description' => ( is => 'ro', required => 1, isa => Str);

1;
