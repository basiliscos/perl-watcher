#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Smart::Comments;
use IO::Socket::INET;
use File::Basename;
use File::Temp qw/ tempdir /;
use Test::More;
use Test::TCP;
use Test::Warnings;

use aliased qw/App::PerlWatcher::Engine/;
use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib" }
use aliased qw/Test::PerlWatcher::AEBackend/;

$ENV{'HOME'} = tempdir( CLEANUP => 1 );

my $config = {};
my $backend = AEBackend->new;
my $engine = Engine->new(config => $config, backend => $backend);
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

$config = {
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
            class => 'App::PerlWatcher::Watcher::Ping',
            config => {
                host    =>  'hostA',
                port    =>  80,
                frequency   =>  1,
            },
        },
        {
            class => 'App::PerlWatcher::Watcher::Ping',
            config => {
                host    =>  'hostB',
                port    =>  80,
                frequency   =>  1,
            },
        },
    ],
};
$engine = Engine->new(config => $config, backend => $backend);
my $watchers = $engine->watchers;
my $statuses = [];
my $callback = sub { push @$statuses, shift };
like $watchers->[0]->description, qr/hostA/, "hostA is the 1st";
like $watchers->[1]->description, qr/hostB/, "hostA is the 2nd";

# generate events in reverse order
$watchers->[1]->_emit_event(LEVEL_NOTICE, $callback);
$watchers->[0]->_emit_event(LEVEL_NOTICE, $callback);
is @$statuses, 2, "got 2 statuses";

like $statuses->[0]->description->(), qr/hostB/, "hostB generates the event 1st";
like $statuses->[1]->description->(), qr/hostA/, "hostB generates the event 2nd";

$statuses = $engine->sort_statuses($statuses);

like $statuses->[0]->description->(), qr/hostA/, "hostA status is the 1st in sorted list";
like $statuses->[1]->description->(), qr/hostB/, "hostB status is the 2nd in sorted list";


done_testing();
