#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::HTTPD;
use Devel::Comments;
use File::Basename;
use FindBin;
use Test::More;

use App::PerlWatcher::Level qw/:levels/;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher::HTTPSimple;

sub getConversion {
    my $file = dirname(__FILE__) . "/data/eur-usd.csv";
    open my $fh, "<", $file or 
        die "could not open $file: $!";
    my $output = do { local $/; <$fh> };
    return $output;
}

my $b = 0;
my $server;

my $end_var = AnyEvent->condvar;

my $scenario = [
    #1 
    {
        req =>  sub {
            return getConversion(); 
        },
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            like $status->description->(), qr/1.3256/;
        },
    },
    
    #2
    {
        req =>  sub {
            undef; 
        },
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            $server = undef;
        },
    },
    
    #3
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_INFO;
        },
    },
    
    #4
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_INFO;
            $end_var->send;
        },
    },
    
];

my ($server_invocations, $callback_invocations) = (0, 0);

my $result_handler = sub {
    return (split(/,/, $_))[1] unless $callback_invocations;
    die("error");
};

my $server_handler = sub {       
    return  $scenario->[$server_invocations++]->{req}->();
};
my $callback_handler = sub {
    return $scenario->[$callback_invocations++]->{res}->(@_);
};

$server = AnyEvent::HTTPD->new;
ok defined($server), "served defined";

$server->reg_cb (
    '/conversion' => sub {
        my ($httpd, $req) = @_;
        $req->respond (
            { content => 
                [
                    'text/html',
                    $server_handler->()
                ]
            },
        );
    },
);

my $url = "http://" . $server->host . ":" . $server->port . "/conversion";

my $engine_config = {
    defaults    => {
        behaviour   => {
            fail => { 
                3   =>  'info',
                5   =>  'alert',
            },
            ok  => { 3 => 'notice' },
        },
    },
};

my %config = (
    url                 =>  $url,
    title               =>  'eur/usd',
    frequency           => 0.1,
    timeout             => 10,
    response_handler    => $result_handler,
    on                  => { 
        ok      => { 1  => 'notice' },
        fail    => { 2 => 'info'   },
    },
);


my $watcher = App::PerlWatcher::Watcher::HTTPSimple->new(
    $engine_config, %config,
);

ok defined($watcher), "watcher was created";

$watcher->start($callback_handler);
$end_var->recv;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";

done_testing();

