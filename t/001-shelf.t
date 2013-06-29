#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use FindBin;
use Test::More;

use App::PerlWatcher::Shelf;
use App::PerlWatcher::Status qw/:levels/;

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

my $shelf = App::PerlWatcher::Shelf->new;

my $s1 = $create_status->(LEVEL_NOTICE);

ok $shelf -> status_changed($s1);
ok $shelf -> status_changed($s1);
ok !$shelf -> stash_status($s1);
ok $shelf -> stash_status($s1);
ok !$shelf -> status_changed($s1);

my $s2 = $create_status->(LEVEL_NOTICE);
ok !$shelf -> status_changed($s2);

my $s3 = $create_status->(LEVEL_INFO);
ok $shelf -> status_changed($s3);

done_testing();

