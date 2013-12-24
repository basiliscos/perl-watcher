#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Smart::Comments;
use Test::More;
use Test::Warnings;

use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib" }

use Test::PerlWatcher::TestWatcher;

my $engine_config = {
    defaults => {
        behaviour => {
            fail => {
                3   =>  'info',
                5   =>  'alert',
            },
            ok  => { 3 => 'notice' },
        }
    }
};

{
    my $w = Test::PerlWatcher::TestWatcher->new(
        engine_config => $engine_config,
        callback      => sub { ... },
    );

    my $map = $w->thresholds_map;
    ok $map, "thresholds map has been defined";

    my $prev_level;
    my $trigger_watcher = sub {
        my $r = $w->_interpret_result_as_level(shift, $prev_level);
        $prev_level = $r;
        return $r;
    };

    is $trigger_watcher->(1), LEVEL_NOTICE;
    is $trigger_watcher->(1), LEVEL_NOTICE;
    is $trigger_watcher->(1), LEVEL_NOTICE;

    is $trigger_watcher->(0), LEVEL_NOTICE;
    is $trigger_watcher->(0), LEVEL_NOTICE;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_ALERT;
    is $trigger_watcher->(0), LEVEL_ALERT;
    is $trigger_watcher->(1), LEVEL_ALERT;
    is $trigger_watcher->(1), LEVEL_ALERT;
    is $trigger_watcher->(1), LEVEL_NOTICE;
    is $trigger_watcher->(0), LEVEL_NOTICE;
    is $trigger_watcher->(0), LEVEL_NOTICE;
    is $trigger_watcher->(0), LEVEL_INFO;
}

{
    my %specific_config = (
        on => {
            fail => {
                2   =>  'info/max',
            },
            ok  => { 1 => 'notice' },
        }
    );

    my $w = Test::PerlWatcher::TestWatcher->new(
        engine_config => $engine_config,
        callback      => sub { ... },
        %specific_config,
    );
    my $prev_level;
    my $trigger_watcher = sub {
        my $r = $w->_interpret_result_as_level(shift, $prev_level);
        $prev_level = $r;
        return $r;
    };

    is $trigger_watcher->(1), LEVEL_NOTICE;
    is $trigger_watcher->(1), LEVEL_NOTICE;
    is $trigger_watcher->(1), LEVEL_NOTICE;

    is $trigger_watcher->(0), LEVEL_NOTICE;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_INFO;
    is $trigger_watcher->(0), LEVEL_INFO;
}

done_testing();

