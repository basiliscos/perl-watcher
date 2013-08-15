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
