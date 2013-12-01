package App::PerlWatcher::Frontend;
{
  $App::PerlWatcher::Frontend::VERSION = '0.18_2'; # TRIAL
}
# ABSTRACT: The base role to which will be notified of updated watcher statuses. 

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;


requires 'update';


requires 'poll';


has 'engine'       => ( is => 'ro', required => 1 );

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Frontend - The base role to which will be notified of updated watcher statuses. 

=head1 VERSION

version 0.18_2

=head1 ATTRIBUTES

=head2 Engine

Holds reference to Engine

=head1 METHODS

=head2 update

The update method will be called with Status, which has been updated.

 $frontend->update($status);

=head2 poll

The poll method will be called when watcher is polling external source

 $frontend->poll($watcher);

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
