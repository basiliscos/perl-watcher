package Test::PerlWatcher::TestWatcher;

use Moo;

with qw/App::PerlWatcher::Watcher/;
sub description { shift;  }
sub build_watcher_guard { ... }

1;
