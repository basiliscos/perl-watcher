package Test::PerlWatcher::TestWatcher;

use Moo;

with qw/App::PerlWatcher::Watcher/;
sub description { shift;  }

1;
