package App::PerlWatcher::WatcherMemory;
{
  $App::PerlWatcher::WatcherMemory::VERSION = '0.19';
}
# ABSTRACT: Represents watcher memory, which can be persisted (detached) from Watcher

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo;

use parent qw/Exporter/;

our @EXPORT_OK = qw/memory_patch/;



has 'data' => (is => 'rw', default => sub { {}; });

sub _monkey_patch {
    my ($class, %patch) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$_"} = $patch{$_} for keys %patch;
}


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

__END__

=pod

=head1 NAME

App::PerlWatcher::WatcherMemory - Represents watcher memory, which can be persisted (detached) from Watcher

=head1 VERSION

version 0.19

=head1 ATTRIBUTES

=head2 'data'

An hashref of arbitrary to be stored within memory.

Storing of coderef's isn't supported.

=head1 FUNCTIONS

=head2 memory_patch

Adds setters and getters for the current package whichi are
proxied by $memory->data of current package, e.g. 

 memory_patch(__PACKAGE__, 'active'); # adds 'active' memorizable attribute

The method assumes, that current the provided package has
'memory' Moo attribute.

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
