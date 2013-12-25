#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Smart::Comments;
use Test::More;
use Test::Warnings;

use aliased qw/App::PerlWatcher::EventItem/;
use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;

use lib 't/lib';

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

# test for generic engine thresholds map
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

# test for generic engine thresholds map in combination with
# watcher-specific threshold map
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

# test for emitted event items
{
    my $w = Test::PerlWatcher::TestWatcher->new(
        engine_config => $engine_config,
        callback      => sub { },
    );

    my $trigger_watcher = sub {
        my ($result, $items_list) = @_;
        my $items = sub { $items_list; };
        my $status;
        my $cb = sub {
            my $status = shift;
        };
        $w->interpret_result($result, $cb, $items);
    };
    my $events_1 = [
        EventItem->new(content => "a"),
        EventItem->new(content => "b"),
        EventItem->new(content => "c"),
    ];
    # we add something to event items memories, to
    # be sure, that the same items will remain
    $events_1->[1]->memory->data->{"x1"} = "y1";
    $events_1->[2]->memory->data->{"x2"} = "y2";
    my $st_1 = $trigger_watcher->(1, $events_1);
    ok $st_1;
    is @{ $st_1->items->() }, @$events_1, "got required items";
    is_deeply $st_1->items->(), $events_1;
    is $st_1->items->()->[1]->memory->data->{"x1"}, "y1";

    my $events_2 = [
        EventItem->new(content => "b"),
        EventItem->new(content => "c"),
        EventItem->new(content => "d"),
        EventItem->new(content => "e"),
    ];
    my $st_2 = $trigger_watcher->(1, $events_2);
    ok $st_2;
    is_deeply $st_2->items->(), $events_2;
    is_deeply $st_2->items->()->[0], $st_1->items->()->[1];
    is_deeply $st_2->items->()->[1], $st_1->items->()->[2];

    my $events_3 = [
        EventItem->new(content => "b"),
    ];
    my $st_3 = $trigger_watcher->(1, $events_3);
    ok $st_3;
    is_deeply $st_3->items->(), $events_3;
    is_deeply $st_3->items->()->[0], $st_2->items->()->[0];
    is $st_3->items->()->[0]->memory->data->{"x1"}, "y1";
}

done_testing();

