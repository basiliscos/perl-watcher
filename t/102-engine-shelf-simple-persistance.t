#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use File::Temp qw/ tempdir /;
use Test::More;
use Test::Warnings;

use aliased 'App::PerlWatcher::Engine';
use App::PerlWatcher::EventItem;
use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;

use lib 't/lib';

use aliased qw/Test::PerlWatcher::AEBackend/;

$ENV{'HOME'} = tempdir( CLEANUP => 1 );

my $config = {
    defaults    => {
        timeout     => 1,
        behaviour   => {
            ok  => {
                1 => 'notice',
                2 => 'info'
            },
            fail => { 1 => 'alert' }
        },
    },
    watchers => [
        {
            class => 'Test::PerlWatcher::TestWatcher',
            config => {
                host    =>  '127.0.0.1',
                frequency   =>  1,
            },
        },
    ],
};
my $backend = AEBackend->new;
my $engine = Engine->new(config => $config, backend => $backend);
ok $engine;

my $watcher = $engine->watchers->[0];
ok $watcher;

my $items = [
    App::PerlWatcher::EventItem->new(content => "a"),
    App::PerlWatcher::EventItem->new(content => "b"),
];

$items->[0]->memory->data->{'_some_key'} = 'some_value';

my $create_status = sub {
    my $level = shift;
    return App::PerlWatcher::Status->new(
        level           => $level,
        watcher         => $watcher,
        description     => sub { $watcher->description },
        items           => sub { $items },
    );
};

my $shelf = $engine->shelf;
my $s1 = $create_status->(LEVEL_NOTICE);
my $s2 = $create_status->(LEVEL_NOTICE);
$shelf -> stash_status($s1);
ok !$shelf -> status_changed($s2);
is_deeply $shelf->statuses->{$s1->watcher}->items()->(), $items;

my $serialized = freeze($engine);
# new engine forces new watcher instances to be created

ok thaw($engine, $serialized);
my $thawed_shelf = $engine->shelf;

ok !$thawed_shelf -> status_changed($s1);
ok !$thawed_shelf -> status_changed($s2);
is_deeply $thawed_shelf->statuses->{$s1->watcher}->items()->(), $items;


# check that watcher's memory is restored
$engine = Engine->new(config => $config, backend => $backend);
$watcher = $engine->watchers->[0];
my $trigger_result = sub {
   $watcher->interpret_result(shift, sub{});
   return $watcher->last_status->level;
};
is $trigger_result->(1), LEVEL_NOTICE;
is $trigger_result->(1), LEVEL_INFO;
$watcher->memory->data->{some_key} = { a => "some data"};
$serialized = freeze($engine);
$engine = Engine->new(config => $config, backend => $backend);

ok thaw($engine, $serialized);

$thawed_shelf = $engine->shelf;
$watcher = $engine->watchers->[0];
ok $watcher;
is $watcher->last_status->level, LEVEL_INFO;
is $watcher->memory->data->{some_key}->{a}, "some data", "data in memory has been restored";

# change the config -> no wather and event should be restored
$config->{watchers}[0]{config}{frequency} = 2;
$engine = Engine->new(config => $config, backend => $backend);

ok thaw($engine, $serialized);

$thawed_shelf = $engine->shelf;
ok $thawed_shelf -> status_changed($s1);
ok $thawed_shelf -> status_changed($s2);

# corrupt the data file
$engine->statuses_file->spew(q/corrupted data/);
$engine = Engine->new(config => $config, backend => $backend);
ok $engine;

done_testing();
