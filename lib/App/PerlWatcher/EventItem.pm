package App::PerlWatcher::EventItem;
{
  $App::PerlWatcher::EventItem::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Moo;

has 'content'   => ( is => 'ro', required => 1 );
has 'timestamp' => ( is => 'ro', default => sub{ time; } );

1;
