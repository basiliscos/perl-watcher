package App::PerlWatcher::Memory;
# ABSTRACT: Represents memory, which can be persisted (detached) for it's owner

use 5.12.0;
use strict;
use warnings;

use Carp;
use Function::Parameters qw(:strict);
use Moo;
use Types::Standard qw/HashRef/;

use parent qw/Exporter/;

our @EXPORT_OK = qw/memory_patch/;


=attr 'data'

An hashref of arbitrary to be stored within memory.

Storing of coderef's isn't supported.

=cut

has 'data' => (is => 'rw', default => sub { {}; }, isa => HashRef);

fun _monkey_patch($class, %patch) {
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$_"} = $patch{$_} for keys %patch;
}

=func memory_patch

Adds setters and getters for the current package which are
proxied by $memory->data of current package, e.g. 

 memory_patch(__PACKAGE__, 'active'); # adds 'active' memorizable attribute

The method assumes, that current the provided package has
'memory' Moo attribute.

=cut

fun memory_patch($class, @attributes) {
    my %patch;
    for my $a (@attributes) {
        $patch{$a} = sub {
            my ($self, $value) = @_;
            my $memory = $self->memory;
            $memory->data->{$a} = $value
                if(defined $value);
            $memory->data->{$a};
        }
    }
    _monkey_patch $class, %patch;
}


1;
