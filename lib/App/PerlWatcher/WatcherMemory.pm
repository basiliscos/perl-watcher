package App::PerlWatcher::WatcherMemory;
# ABSTRACT: Represents watcher memory, which can be persisted (detached) from Watcher

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo;

use parent qw/Exporter/;

our @EXPORT_OK = qw/memory_patch/;


=attr 'data'

An hashref of arbitrary to be stored within memory.

Storing of coderef's isn't supported.

=cut

has 'data' => (is => 'rw', default => sub { {}; });

sub _monkey_patch {
    my ($class, %patch) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$_"} = $patch{$_} for keys %patch;
}

=func memory_patch

Adds setters and getters for the current package whichi are
proxied by $memory->data of current package, e.g. 

 memory_patch(__PACKAGE__, 'active'); # adds 'active' memorizable attribute

The method assumes, that current the provided package has
'memory' Moo attribute.

=cut

sub memory_patch {
    my ($class, @attributes) = @_;
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
