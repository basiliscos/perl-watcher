package App::PerlWatcher::Memorizable;
{
  $App::PerlWatcher::Memorizable::VERSION = '0.20';
}
# ABSTRACT: The base role to allow class to have 'memory' attributebrowser

use 5.12.0;
use strict;
use warnings;

use aliased qw/App::PerlWatcher::Memory/;
use Moo::Role;


has 'memory'    => ( is => 'rw', default => sub{ Memory->new });


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Memorizable - The base role to allow class to have 'memory' attributebrowser

=head1 VERSION

version 0.20

=head1 ATTRIBUTES

=head2 memory

Stores current class state (memory). When the object is persisted,
only it's memory is been stored

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
