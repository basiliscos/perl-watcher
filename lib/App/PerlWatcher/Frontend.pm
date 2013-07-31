package App::PerlWatcher::Frontend;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;

requires 'update';
requires 'show';
has 'engine'       => ( is => 'ro', required => 1 );
has 'last_seen'    => ( is => 'rw', default => sub{ time; } );

1;
