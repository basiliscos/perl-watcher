#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Smart::Comments;
use IO::Socket::INET;
use File::Basename;
use Test::More;
use Test::TCP;

my $server = Test::TCP->new(
  code => sub {
    my $port = shift;
    my $socket = IO::Socket::INET->new(
        LocalPort => $port,
        LocalHost => '127.0.0.1',
        Proto => 'tcp',
        Listen => 5,
    ) or croak ("ERROR in Socket Creation : $!");
    while(1) {
        my $client_socket = $socket->accept();
        $client_socket->close();
    }
  },
);

use App::PerlWatcher::Levels;
use App::PerlWatcher::Watcher::Ping;

my $end_var = AnyEvent->condvar;
my ($s1, $s2);

my $watcher;
my $scenario = [
    #1
    {
        res =>  sub {
            my $status = shift;
            ok $status;
            $s1 = $status;
            $watcher->force_poll;
        },
    },

    #2
    {
        res =>  sub {
            my $status = shift;
            ok $status;
            $s2 = $status;
            $end_var->send;
            $watcher->active(0);
        },
    },

];

my $callback_invocations = 0;
my $callback_handler = sub {
    return $scenario->[$callback_invocations++]->{res}->(@_);
};

my $engine_config = {
    defaults    => {
        timeout     => 1,
        behaviour   => {
            fail => {
                1   =>  'alert',
            },
            ok  => { 1 => 'notice' },
        },
    },
};

$watcher = App::PerlWatcher::Watcher::Ping->new(
    host            => "localhost",
    port            => $server->port,
    frequency       => 9,
    timeout         => 10,
    callback        => $callback_handler,
    engine_config   => $engine_config,
);

ok defined($watcher), "watcher was created";
$watcher->start;
$end_var->recv;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";
ok !$s1->updated_from($s1);
ok !$s1->updated_from($s2);
ok !$s2->updated_from($s1);
ok !$s2->updated_from($s2);
$watcher->active(0);

# testing icmp ping of localhost
{
    my $succesful_icmp_ping = 0;
    my $end_var =  AnyEvent->condvar;
    my $cb = sub {
        my $status = shift;
        $succesful_icmp_ping = $status->level == LEVEL_NOTICE;
        $end_var->send;
    };
    my $icmp_watcher = App::PerlWatcher::Watcher::Ping->new(
        callback        => $cb,
        host            => "localhost",
        frequency       => 9,
        timeout         => 2,
        engine_config   => $engine_config,
    );
    $icmp_watcher->start;
    $end_var->recv;
    ok $succesful_icmp_ping, "localhost is pinged via icmp successfully";
}

# testing icmp ping of non-existent host
{
    my $succesful_icmp_ping = 0;
    my $end_var =  AnyEvent->condvar;
    my $cb = sub {
        my $status = shift;
        $succesful_icmp_ping = $status->level == LEVEL_NOTICE;
        $end_var->send;
    };
    my $icmp_watcher = App::PerlWatcher::Watcher::Ping->new(
        callback        => $cb,
        host            => "invalid",
        frequency       => 9,
        timeout         => 2,
        engine_config   => $engine_config,
    );
    $icmp_watcher->start;
    $end_var->recv;
    ok !$succesful_icmp_ping, "invalid isn't pinged via icmp";
}

done_testing;
