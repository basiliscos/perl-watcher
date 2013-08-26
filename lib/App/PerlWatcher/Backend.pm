package App::PerlWatcher::Backend;
{
  $App::PerlWatcher::Backend::VERSION = '0.14_01';
}
# ABSTRACT: The base role to which provides event loop (AnyEvent, PE, Gtk, KDE etc.)

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;


requires 'start_loop';


requires 'stop_loop';

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Backend - The base role to which provides event loop (AnyEvent, PE, Gtk, KDE etc.)

=head1 VERSION

version 0.14_01

=head1 METHODS

=head2 start_loop

Starts event loop

=head2 stop_loop

Stops event loop;

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
