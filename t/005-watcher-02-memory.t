#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Test::More;

use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher;
use App::PerlWatcher::WatcherMemory;

my $engine_config = {
    fail => { 
        3   =>  'info',
        5   =>  'alert',
    },
    ok  => { 3 => 'notice' },
};

my $map = App::PerlWatcher::Watcher::calculate_threshods($engine_config, {});
ok $map, "thresholds map has been defined";

my $wm = App::PerlWatcher::WatcherMemory->new(thresholds_map=>$map);

is $wm->interpret_result(1), LEVEL_NOTICE;
is $wm->interpret_result(1), LEVEL_NOTICE;
is $wm->interpret_result(1), LEVEL_NOTICE;

is $wm->interpret_result(0), LEVEL_NOTICE;
is $wm->interpret_result(0), LEVEL_NOTICE;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_ALERT;
is $wm->interpret_result(0), LEVEL_ALERT;
is $wm->interpret_result(1), LEVEL_ALERT;
is $wm->interpret_result(1), LEVEL_ALERT;
is $wm->interpret_result(1), LEVEL_NOTICE;
is $wm->interpret_result(0), LEVEL_NOTICE;
is $wm->interpret_result(0), LEVEL_NOTICE;
is $wm->interpret_result(0), LEVEL_INFO;

my %specific_config = (
    fail => { 
        2   =>  'info/max',
    },
    ok  => { 1 => 'notice' },
);

$map = App::PerlWatcher::Watcher::calculate_threshods(\%specific_config, $engine_config);
$wm = App::PerlWatcher::WatcherMemory->new(thresholds_map=>$map);

is $wm->interpret_result(1), LEVEL_NOTICE;
is $wm->interpret_result(1), LEVEL_NOTICE;
is $wm->interpret_result(1), LEVEL_NOTICE;

is $wm->interpret_result(0), LEVEL_NOTICE;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_INFO;
is $wm->interpret_result(0), LEVEL_INFO;

done_testing();

