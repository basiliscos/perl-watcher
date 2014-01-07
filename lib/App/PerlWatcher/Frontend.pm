package App::PerlWatcher::Frontend;
# ABSTRACT: The base role to which will be notified of updated watcher statuses.

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;

=method update

The update method will be called with Status, which has been updated.

 $frontend->update($status);

=cut

requires 'update';

=method poll

The poll method will be called when watcher is polling external source

 $frontend->poll($watcher);

=cut

requires 'poll';

=attr Engine

Holds reference to Engine

=cut

has 'engine'       => ( is => 'ro', required => 1 );

1;
