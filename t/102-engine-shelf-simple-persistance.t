#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use File::Temp qw/ tempdir /;
use Test::More;

use App::PerlWatcher::Engine;
use App::PerlWatcher::EventItem;
use App::PerlWatcher::Level qw/:levels/;
use App::PerlWatcher::Status;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;

$ENV{'HOME'} = tempdir( CLEANUP => 1 );

{
    package Test::PerlWatcher::TestWatcher;
    use Moo;
    with qw/App::PerlWatcher::Watcher/;
    sub description { shift;  }
}

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

my $engine = App::PerlWatcher::Engine->new($config, 'AnyEvent');
ok $engine;

my $watcher = @{ $engine->get_watchers }[0];
ok $watcher;

my $items = [ 
    App::PerlWatcher::EventItem->new(content => "a"),
    App::PerlWatcher::EventItem->new(content => "b"),
];

my $create_status = sub {
    my $level = shift;
    return App::PerlWatcher::Status->new(
        level           => $level,
        watcher         => $watcher,
        description     => sub { $watcher->description },
        items           => sub { $items },
    );                               
};

my $shelf = $engine->statuses_shelf;
my $s1 = $create_status->(LEVEL_NOTICE);
my $s2 = $create_status->(LEVEL_NOTICE);
$shelf -> stash_status($s1);
ok !$shelf -> status_changed($s2);
is_deeply $shelf->statuses->{$s1->watcher}->items()->(), $items;

my $serialized = freeze($engine);
# new engine forces new watcher instances to be created

ok thaw($engine, $serialized);
my $thawed_shelf = $engine->statuses_shelf;

ok !$thawed_shelf -> status_changed($s1);
ok !$thawed_shelf -> status_changed($s2);
is_deeply $thawed_shelf->statuses->{$s1->watcher}->items()->(), $items;


# check that watcher's memory is restored
$engine = App::PerlWatcher::Engine->new($config, 'AnyEvent');
$watcher = @{ $engine->get_watchers }[0];
my $memory = $watcher->memory;
is $memory->interpret_result(1), LEVEL_NOTICE;
is $memory->interpret_result(1), LEVEL_INFO;
is $memory->last_level, LEVEL_INFO;
$serialized = freeze($engine);
$engine = App::PerlWatcher::Engine->new($config, 'AnyEvent');

ok thaw($engine, $serialized);

$thawed_shelf = $engine->statuses_shelf;
$watcher = @{ $engine->get_watchers }[0];
ok $watcher;
is $watcher->memory->last_level, LEVEL_INFO;

# change the config -> no wather and event should be restored 
$config->{watchers}[0]{config}{frequency} = 2;
$engine = App::PerlWatcher::Engine->new($config, 'AnyEvent');

ok thaw($engine, $serialized);

$thawed_shelf = $engine->statuses_shelf;
ok $thawed_shelf -> status_changed($s1);
ok $thawed_shelf -> status_changed($s2);

# corrupt the data file
App::PerlWatcher::Engine::_statuses_file->spew(q/corrupted data/);
$engine = App::PerlWatcher::Engine->new($config, 'AnyEvent');
ok $engine;

done_testing();

