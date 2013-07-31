package App::PerlWatcher::EventItem;

use 5.12.0;
use strict;
use warnings;

use Moo;

has 'content'   => ( is => 'ro', required => 1 );
has 'timestamp' => ( is => 'ro', default => sub{ time; } );

1;
