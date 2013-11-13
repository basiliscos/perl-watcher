#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::HTTPD;
use Smart::Comments -ENV;
use File::Basename;
use Path::Class;
use Test::More;

use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher::Rss;

sub getRss {
    my $file = file(dirname(__FILE__) . "/data/opennet.ru.rss");
    return scalar $file->slurp;
}

my $server;

my ($s1, $s2);

my $end_var = AnyEvent->condvar;
my $watcher;
my $scenario = [
    #1
    {
        req =>  sub { return getRss(); },
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            my $items = $status->items->();
            is @{ $items }, 5, "got 5 items (#1)";
            ok $_->does('App::PerlWatcher::Openable') && $_->url, "EventItem is openable"
                for (@{ $items });
            $s1 = $status;
            $watcher->force_poll;

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
            ok $_->does('App::PerlWatcher::Openable') && $_->url, "EventItem is openable"
                for (@{ $items });
            $s2 = $status;
            $server = undef;
            $watcher->force_poll;
        },
    },

    #3
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_NOTICE;
            my $items = $status->items->();
            ok $_->does('App::PerlWatcher::Openable') && $_->url, "EventItem is openable"
                for (@{ $items });
            is @{ $items }, 5, "got 5 items (#2)";
            $watcher->force_poll;
        },
    },

    #4
    {
        res =>  sub {
            my $status = shift;
            is $status->level, LEVEL_INFO;
            $watcher->active(0);
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

$watcher = App::PerlWatcher::Watcher::Rss->new(
    url         => $rss_url1,
    items       => 5,
    frequency   => 10, # does not matter, managed manually
    timeout     => 1,
    title       => 'la-la-title',
    on          => { fail => { 2 => 'info' } },
    engine_config => $engine_config,
    callback    => $callback_handler,
);

ok defined($watcher), "watcher was created";
like $watcher->description, qr/la-la-title/, "check watcher title";

$watcher->start;
$end_var->recv;

is $server_invocations , scalar (grep { $_->{req} } @$scenario), "correct number of server invocations";
is $callback_invocations , scalar (grep { $_->{res} } @$scenario), "correct number of callback invocations";

ok !$s1->updated_from($s1);
ok !$s1->updated_from($s2);
ok !$s2->updated_from($s2);
ok !$s2->updated_from($s1);

### OK

done_testing();
