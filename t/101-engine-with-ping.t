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

use aliased 'App::PerlWatcher::Engine';
use aliased 'App::PerlWatcher::Frontend';
use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Shelf;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib" }

use Test::PerlWatcher::FrontEnd;
use aliased qw/Test::PerlWatcher::AEBackend/;

$ENV{'HOME'} = tempdir( CLEANUP => 1 );

# watcher event registration
my $server = Test::TCP->new(
  code => sub {
    my $port = shift;
    my $socket = IO::Socket::INET->new(
        LocalPort => $port,
        LocalHost => '127.0.0.1',
        Proto => 'tcp',
        Listen => 1,
    ) or croak ("ERROR in Socket Creation : $!");
    while(1) {
        my $client_socket = $socket->accept();
        $client_socket->close();
    }
  },
);

my $engine;
my $shelf = App::PerlWatcher::Shelf->new;

my $scenario = [
    #1
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            ok $shelf -> status_changed($status);
            ok !$shelf -> stash_status($status);
            ok !$shelf -> status_changed($status);
        },
    },

    #2
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_INFO;
            ok $shelf -> status_changed($status);
            $server = undef;
        },
    },

    #3
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_ALERT;
            ok $shelf -> status_changed($status);
        },
    },
];

my $callback_invocations = 0;
my $callback_handler = sub {
    return $scenario->[$callback_invocations++]->{res}->(@_);
};

my $frontend = Test::PerlWatcher::FrontEnd->new(engine => $engine, cb => $callback_handler);

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
            class => 'App::PerlWatcher::Watcher::Ping',
            config => {
                host    =>  '127.0.0.1',
                port    =>  $server->port,
                frequency   =>  1,
            },
        },
    ],
};
$engine = Engine->new(
    config      => $config,
    backend     => AEBackend->new,
    frontend    => $frontend,
    );
ok $engine;

my $end_var = AnyEvent->condvar;
my $w = AnyEvent->timer (
    after => 2.9,
    cb => sub {
        $engine->stop;
    }
);
$engine->start;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";

done_testing();
