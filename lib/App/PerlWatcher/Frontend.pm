package App::PerlWatcher::Frontend;
# ABSTRACT: The base role to which will be notified of updated watcher statuses. 

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;

=method start

The update method will be called with Status, which has been updated.

=cut

requires 'update';

=attr Engine

Holds reference to Engine

=cut

has 'engine'       => ( is => 'ro', required => 1 );

1;
