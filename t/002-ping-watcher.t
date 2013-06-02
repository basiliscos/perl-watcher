#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Devel::Comments;
use IO::Socket::INET;
use File::Basename;
use FindBin;
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
        $client_socket->send("hello");
        $client_socket->close();
    }
  },
);

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
require App::PerlWatcher::Watcher::Ping;

my $scenario = [
    #1 
    {
        res =>  sub {
            my $status = shift;
            ok $status->updated, "status has been updated";
        },
    },
    
    #2 
    {
        res =>  sub {
            my $status = shift;
            ok $status->updated, "status has been updated";
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
                3   =>  'info',
                5   =>  'alert',
            },
            ok  => { 3 => 'notice' },
        },
    },
};

my $watcher = App::PerlWatcher::Watcher::Ping->new(
    $engine_config,
    (host => "localhost", port => $server->port, frequency => 1, timeout => 1),
);

ok defined($watcher), "watcher was created";

$watcher->start($callback_handler);

my $end_var = AnyEvent->condvar;
my $w = AnyEvent->timer (
    after => 1.9, 
    cb => sub {
        $end_var->send;
    }
);
$end_var->recv;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";

done_testing();
