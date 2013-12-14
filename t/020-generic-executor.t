#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Smart::Comments -ENV;
use File::Spec::Functions;
use File::Temp qw/ tempdir /;
use List::MoreUtils qw/any none/;
use Path::Tiny;
use Test::More;

use App::PerlWatcher::Levels;
use aliased qw/App::PerlWatcher::Watcher::GenericExecutor/;

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

{
    my $tmp_dir = tempdir( CLEANUP => 1 );

    mkdir catfile($tmp_dir, "a") or die($@);
    mkdir catfile($tmp_dir, "b") or die($@);
    my $file_database = path(catfile($tmp_dir, "a", "my-database.txt"));
    my $file_X        = path(catfile($tmp_dir, "b", "X.txt"));
    my $file_strage   = path(catfile($tmp_dir, "b", "strange_file.txt"));

    $_->spew("data")
        for ($file_database, $file_X);

    my $watcher;
    my $end_cv = AnyEvent->condvar;

    sub has_filename {
        my ($name, $items) = @_;
        my $re = qr/$name/;
        my $result = any { $_->content =~ /$re/ } @$items;
        return $result;
    }

    my $scenario = [
        sub {
            my $status = shift;
            my $items = $status->items->();
            ### $items
            is @$items, 2, "has 2 items";

            ok has_filename($file_database->basename, $items), "has database among items";
            ok has_filename($file_X->basename, $items), "has X among items";
            is $status->level, LEVEL_NOTICE, "nothing happend - notice";

            $file_strage->spew("data");
            $watcher->force_poll;
        },
        sub {
            my $status = shift;
            my $items = $status->items->();
            is @$items, 3, "has 3 items";

            ok has_filename($file_strage->basename, $items), "has strange file among items";
            is $status->level, LEVEL_WARN, "strange file - got warning";

            unlink $file_database;
            #unlink $file_strage;
            $watcher->force_poll;
        },
        sub {
            my $status = shift;
            my $items = $status->items->();
            is @$items, 2, "has 2 items";

            ok !has_filename($file_database->basename, $items), "hasn't database file among items";
            is $status->level, LEVEL_ALERT, "no database file - got alert";

            $watcher->active(0);
            $end_cv->send;
        },
    ];
    my $invocations = 0;
    my $poll_started = 0;
    my $poll_callback = sub {
        my $w = shift;
        is "$w", "$watcher",  "watcher arg is passed to poll_callback";
        $poll_started = 1;
    };
    my $callback_handler = sub {
        ok $poll_started, "poll callback has been invokeed before main callback";
        $scenario->[$invocations++]->(@_);
        $poll_started = 0;
    };

    my $ls_command = $^O eq 'MSWin32' ? "cmd" : "ls";
    my @ls_command_args = $^O eq 'MSWin32' ? ("/C", "dir", "/B") : ("-1A");

    my %watcher_config = (
        command       => $ls_command,
        arguments     => [
            @ls_command_args,
            catfile($tmp_dir, "a"),
            catfile($tmp_dir, "b")
        ],
        timeout       => 1,
        filter        => sub {
            ($_ !~ /^\.{1,2}$/) && (/\S+/) && ($_ !~ /\Q$tmp_dir\E/)
        },
        rules         => [
            alert => sub { none { /my-database.txt/ } @_ },
            warn  => sub { any { /strange_file.txt/ } @_ },
        ],
        engine_config => $engine_config,
        callback      => $callback_handler,
        poll_callback => $poll_callback,
    );
    $watcher = GenericExecutor->new(%watcher_config);
    my $w2 = GenericExecutor->new(%watcher_config);
    is "$watcher", "$w2", "watchers have the same id";

    $watcher->start;

    $end_cv->recv;
    is $invocations, @$scenario, "all screnario items has been executed";
}

# testing timeout
SKIP: {
	skip "timeout handling for generic executor isn't implemented"
		. " for windows", 1 if($^O eq 'MSWin32');
    my $wait_cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(
        after => 2,
        cb    => sub { $wait_cv->send(0) },
    );
    my $w3 = GenericExecutor->new(
		command   => $^X,
		arguments => ["-e", "sleep(10)"],
		timeout   => 1,
		engine_config => $engine_config,
		callback  => sub {
			my $status = shift;
			### $status
			$wait_cv->send(1);
		}
	);
    $w3->start;
    ok $wait_cv->recv, "timeout has been handled correctly";
}

done_testing;
