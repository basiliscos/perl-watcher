#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Gtk2;
use Devel::Comments;
use IO::Socket::INET;
use File::Basename;
use FindBin;
use Test::More;
use Test::TCP;


BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
use App::PerlWatcher::Status qw/:levels/;
require App::PerlWatcher::Engine;

my $config = {
    backend => 'Gtk2',
};
my $engine = App::PerlWatcher::Engine->new($config);
ok $engine;

# start/stop test
my $stopped = 0;
my $w = AnyEvent->timer (
    after => 0, 
    cb => sub {
        $engine->stop;
        $stopped = 0;
    }
);
$engine->start;
ok $stopped == 0;

# test stash statuses

my $watcher = "watcher";
my $update_detector = sub {
    my ($a, $b) = @_;
    my $result = !($a->level == $b->level); 
    # $a
    # $b
    # $result
    return $result;
};

my $create_status = sub {
    my $level = shift;
    return App::PerlWatcher::Status->new(
        level           => $level,
        watcher         => \$watcher,
        update_detector => $update_detector
    );
};

my $s1 = $create_status->(LEVEL_NOTICE);

ok $engine -> has_changed($s1);
ok $engine -> has_changed($s1);
ok $engine -> stash($s1);
ok !$engine -> has_changed($s1);

my $s2 = $create_status->(LEVEL_NOTICE);
ok !$engine -> has_changed($s2);

my $s3 = $create_status->(LEVEL_INFO);
ok $engine -> has_changed($s3);

done_testing();
