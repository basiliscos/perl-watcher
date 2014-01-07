package App::PerlWatcher::Memorizable;
# ABSTRACT: The base role to allow class to have 'memory' attributebrowser

use 5.12.0;
use strict;
use warnings;

use aliased qw/App::PerlWatcher::Memory/;
use Moo::Role;
use Type::Tiny::Role;

=attr memory

Stores current class state (memory). When the object is persisted,
only it's memory is been stored

=cut

has 'memory'=> (
    is => 'rw',
    default => sub{ Memory->new },
    isa => Type::Tiny::Role->new(role => Memory),
);


1;
