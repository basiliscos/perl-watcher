#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Devel::Comments;
use File::Basename;
use File::Temp qw/ tempdir /;
use Test::More;

use App::PerlWatcher::Levels;
use App::PerlWatcher::Watcher::FileTail;

my $tmpdir = tempdir( CLEANUP => 1 );
my $filename = "$tmpdir/sample.log";

my $received_status;

my $callback_handler = sub {
    $received_status = shift;
};

my $watcher = App::PerlWatcher::Watcher::FileTail->new(
    file            => $filename,
    lines_number    => 5,
    engine_config   => {},
);

ok defined($watcher), "watcher was created";
$watcher->start($callback_handler);
is $received_status->level, LEVEL_ANY;

done_testing;
