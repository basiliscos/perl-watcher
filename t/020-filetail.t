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

use App::PerlWatcher::Watcher::FileTail;


my $end_var = AnyEvent->condvar;

my $filename,
my $file;

my ($s1, $s2);
my $timer;

my $marker = "MarkeR";

my $validate = sub {
    my $items = shift;
    like ($_->content, qr/$marker/ ) for ( @$items );
};

my $scenario = [
    #1 
    {
        res =>  sub {
            my $status = shift;
            my $items = $status->items->();
            is @{ $items }, 1, "got 1 item (#1)";
            $validate->($items);
            $s1 = $status;
            AnyEvent::postpone {
                say $file "$marker 1st line";
                say $file "non-interesting line 1";
                say $file "non-interesting line 2";
                say $file "non-interesting line 3";
            };
        },
    },

    {
        res =>  sub {
            my $status = shift;
            my $items = $status->items->();
            is @{ $items }, 2, "got 2 items (#2)";
            $validate->($items);
            $s2 = $status;
            AnyEvent::postpone {
                    $end_var->send;
            };
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
say $file "$marker initial line";

my $filter = sub {
    $_ =~ /$marker/;
};
# validate the filter itserlf
ok $filter->(local $_ = "$marker");
ok !$filter->(local $_ = "empty");
ok !$filter->(local $_ = "Z");

my $watcher = App::PerlWatcher::Watcher::FileTail->new(
    file            => $filename, 
    lines_number    => 5,
    filter          => $filter,
    engine_config   => {},
);

ok defined($watcher), "watcher was created";
like "$watcher", qr/FileTail/, "has overloaded toString"; 

$watcher->start($callback_handler);
$end_var->recv;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";

ok !$s1->updated_from($s1);
ok  $s1->updated_from($s2);
ok !$s2->updated_from($s2);
ok  $s2->updated_from($s1);

done_testing();
