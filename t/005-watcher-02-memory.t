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

my $w = Test::PerlWatcher::TestWatcher->new(
    engine_config => $engine_config,
    callback      => sub { ... },
);


my $map = $w->thresholds_map;
ok $map, "thresholds map has been defined";

is $w->_interpret_result_as_level(1), LEVEL_NOTICE;
is $w->_interpret_result_as_level(1), LEVEL_NOTICE;
is $w->_interpret_result_as_level(1), LEVEL_NOTICE;

is $w->_interpret_result_as_level(0), LEVEL_NOTICE;
is $w->_interpret_result_as_level(0), LEVEL_NOTICE;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_ALERT;
is $w->_interpret_result_as_level(0), LEVEL_ALERT;
is $w->_interpret_result_as_level(1), LEVEL_ALERT;
is $w->_interpret_result_as_level(1), LEVEL_ALERT;
is $w->_interpret_result_as_level(1), LEVEL_NOTICE;
is $w->_interpret_result_as_level(0), LEVEL_NOTICE;
is $w->_interpret_result_as_level(0), LEVEL_NOTICE;
is $w->_interpret_result_as_level(0), LEVEL_INFO;

my %specific_config = (
    on => {
        fail => {
            2   =>  'info/max',
        },
        ok  => { 1 => 'notice' },
    }
);

$w = Test::PerlWatcher::TestWatcher->new(
    engine_config => $engine_config,
    callback      => sub { ... },
    %specific_config,
);

is $w->_interpret_result_as_level(1), LEVEL_NOTICE;
is $w->_interpret_result_as_level(1), LEVEL_NOTICE;
is $w->_interpret_result_as_level(1), LEVEL_NOTICE;

is $w->_interpret_result_as_level(0), LEVEL_NOTICE;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_INFO;
is $w->_interpret_result_as_level(0), LEVEL_INFO;

done_testing();

