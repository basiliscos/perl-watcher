#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Devel::Comments;
use File::Basename;
use File::Temp qw/ tempdir /;
use FindBin;
use Test::More;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
require App::PerlWatcher::Watcher::FileTail;

my $filename,
my $file;

my $scenario = [
    #1 
    {
        res =>  sub {
            my $status = shift;
            ok $status->updated, "status has been updated";
            my $items = $status->items->();
            is @{ $items }, 1, "got 1 item (#1)";
            #say $file "line 1";
        },
    },

## not working yet ??    
    #2 
    # {
        # res =>  sub {
            # my $status = shift;
            # ok $status->updated, "status has been updated";
            # syswrite $file, "line 2";
        # },
    # },
    
    #3 
    # {
        # res =>  sub {
            # my $status = shift;
            # ok $status->updated, "status has been updated";
        # },
    # },
    
];

my $callback_invocations = 0;
my $callback_handler = sub {
    return $scenario->[$callback_invocations++]->{res}->(@_);
};

my $tmpdir = tempdir( CLEANUP => 1 );
$filename = "$tmpdir/sample.log";
open($file, ">", $filename) 
    or croak("can't open file $filename: $!");
$file->autoflush;
say $file "initial line";

my $watcher = App::PerlWatcher::Watcher::FileTail->new(
    0,
    (file => $filename, lines => 5),
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
