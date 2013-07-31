#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Devel::Comments;
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

use App::PerlWatcher::Watcher::Ping;

my $end_var = AnyEvent->condvar;
my ($s1, $s2);

my $scenario = [
    #1 
    {
        res =>  sub {
            my $status = shift;
            ok $status;
            $s1 = $status;
        },
    },
    
    #2 
    {
        res =>  sub {
            my $status = shift;
            ok $status;
            $s2 = $status;
            $end_var->send;
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
    host            => "localhost", 
    port            => $server->port, 
    frequency       => 0.1, 
    timeout         => 1,
    engine_config   => $engine_config,
);

ok defined($watcher), "watcher was created";

$watcher->start($callback_handler);
$end_var->recv;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";
ok !$s1->updated_from($s1);
ok !$s1->updated_from($s2);
ok !$s2->updated_from($s1);
ok !$s2->updated_from($s2);


done_testing();
