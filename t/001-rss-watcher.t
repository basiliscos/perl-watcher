#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Devel::Comments;
use File::Basename;
use FindBin;
use Test::More;
use Test::HTTP::Server;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
require App::PerlWatcher::Watcher::Rss;

sub getRss {
    my $file = dirname(__FILE__) . "/data/rss1.rss";
    open my $fh, "<", $file or 
        die "could not open $file: $!";
    my $output = do { local $/; <$fh> };
    return $output;
}

my ($s1, $s2);

my $end_var = AnyEvent->condvar;

my $scenario = [
    #1 
    {
        req =>  sub { return getRss(); },
        res =>  sub {
            my $status = shift;
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
            my $items = $status->items->();
            is @{ $items }, 5, "got 5 items (#2)";
            $s2 = $status;
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

my $server = Test::HTTP::Server->new();
ok defined($server), "served defined";

my $rss_url1 = $server->uri . "rss1";

my $watcher = App::PerlWatcher::Watcher::Rss->new(
    0,
    (url => $rss_url1, items => 5, frequency => 0.01, timeout => 1, title => 'la-la-title'),
);

ok defined($watcher), "watcher was created";
like $watcher->description, qr/la-la-title/, "check watcher title";


sub Test::HTTP::Server::Request::rss1 {
    my $self = shift;
    return $server_handler->();
}

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
