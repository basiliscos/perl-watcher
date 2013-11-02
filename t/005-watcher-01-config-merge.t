#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Smart::Comments;
use Test::More;

use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher;

my $generic = {
    3   =>  'info',
    5   =>  'alert',
};

my $specific = {
    2   =>  'info',
};

my $expected = {
    2   => 'info',
    5   => 'alert',
};

my $got = App::PerlWatcher::Watcher::_merge($specific, $generic);
is_deeply $got, $expected;

$expected = {
    3   => 'info',
    5   => 'alert',
};
$got = App::PerlWatcher::Watcher::_merge($generic, $specific);
is_deeply $got, $expected;

$specific = {
    2   =>  'info/max',
};
$expected = {
    2   => 'info',
};
$got = App::PerlWatcher::Watcher::_merge($specific, $generic);
is_deeply $got, $expected;

$got = App::PerlWatcher::Watcher::_merge({}, $generic);
is_deeply $got, $generic;


done_testing();

