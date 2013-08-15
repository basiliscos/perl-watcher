package App::PerlWatcher::Frontend;
{
  $App::PerlWatcher::Frontend::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;

requires 'update';
has 'engine'       => ( is => 'ro', required => 1 );
has 'last_seen'    => ( is => 'rw', default => sub{ time; } );

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Frontend

=head1 VERSION

version 0.12

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
