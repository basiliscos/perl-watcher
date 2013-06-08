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
use App::PerlWatcher::Watcher::FileTail;


my $end_var = AnyEvent->condvar;

my $filename,
my $file;

my ($s1, $s2);
my $timer;

my $scenario = [
    #1 
    {
        res =>  sub {
            my $status = shift;
            my $items = $status->items->();
            is @{ $items }, 1, "got 1 item (#1)";
            $s1 = $status;
            $timer = AnyEvent->timer(after => 0, cb => sub {
                    say $file "1st line";
            });
        },
    },

    {
        res =>  sub {
            my $status = shift;
            my $items = $status->items->();
            is @{ $items }, 2, "got 2 items (#2)";
            $s2 = $status;
            $timer = AnyEvent->timer(after => 0, cb => sub {
                    $end_var->send;
            });
        },
    },
    
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
$end_var->recv;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";

ok !$s1->updated_from($s1);
ok  $s1->updated_from($s2);
ok !$s2->updated_from($s2);
ok  $s2->updated_from($s1);

done_testing();
