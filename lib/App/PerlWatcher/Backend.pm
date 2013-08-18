package App::PerlWatcher::Backend;
# ABSTRACT: The base role to which provides event loop (AnyEvent, PE, Gtk, KDE etc.)

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;

=method start_loop

Starts event loop

=cut

requires 'start_loop';

=method stop_loop

Stops event loop;

=cut

requires 'stop_loop';

1;
