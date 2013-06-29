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

use App::PerlWatcher::Watcher::Rss;
use App::PerlWatcher::Status qw/:levels/;

sub getRss {
    my $file = dirname(__FILE__) . "/data/rss1.rss";
    open my $fh, "<", $file or 
        die "could not open $file: $!";
    my $output = do { local $/; <$fh> };
    return $output;
}

my $server;

my ($s1, $s2);

my $end_var = AnyEvent->condvar;

my $scenario = [
    #1 
    {
        req =>  sub { return getRss(); },
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            my $items = $status->items->();
            is @{ $items }, 5, "got 5 items (#1)";
            $s1 = $status;
        },
    },
    
    #2 
    {
        req =>  sub { return getRss(); },
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            my $items = $status->items->();
            is @{ $items }, 5, "got 5 items (#2)";
            $s2 = $status;
            $server = undef;
        },
    },
    
    #3 
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            my $items = $status->items->();
            is @{ $items }, 5, "got 5 items (#2)";
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
my $server_handler = sub {
    return $scenario->[$server_invocations++]->{req}->();
};
my $callback_handler = sub {
    return $scenario->[$callback_invocations++]->{res}->(@_);
};

$server = AnyEvent::HTTPD->new;
$server->reg_cb (
    '/rss1' => sub {
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

ok defined($server), "served defined";
my $rss_url1 = "http://" . $server->host . ":" . $server->port . "/rss1";

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

my $watcher = App::PerlWatcher::Watcher::Rss->new(
    $engine_config,
    (   url => $rss_url1, items => 5, frequency => 1, timeout => 1, title => 'la-la-title',
        on => { fail => { 2 => 'info' } },
    ),
);

ok defined($watcher), "watcher was created";
like $watcher->description, qr/la-la-title/, "check watcher title";

$watcher->start($callback_handler);
$end_var->recv;

# invoked in other forked process. Not testing
#is $server_invocations  , scalar @$scenario, "correct number of server invocations";
is $callback_invocations, scalar @$scenario, "correct number of callback invocations";

ok !$s1->updated_from($s1);
ok !$s1->updated_from($s2);
ok !$s2->updated_from($s2);
ok !$s2->updated_from($s1);

done_testing();
