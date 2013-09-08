#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Test::More;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib" }
use Test::PerlWatcher::TestWatcher;

my %engine_config;
my %watcher_init = (
    a=>'b', c=>1, e=>{d=>5},
    engine_config => \%engine_config,
    callback      => sub { },
);
my $w1 = Test::PerlWatcher::TestWatcher->new(%watcher_init); 
my $w1_1 = Test::PerlWatcher::TestWatcher->new(%watcher_init);

is $w1->unique_id, $w1_1->unique_id, "different watcher instances have the same id with the same configs";
is "$w1", "$w1_1", "different watcher instances have the same id with the same configs (string overloaded version)";

$watcher_init{c} = 2;
my $w2 = Test::PerlWatcher::TestWatcher->new(%watcher_init);
ok !($w1->unique_id eq $w2->unique_id), "different watcher instances have the different configs don't have the same ids";

$watcher_init{describer} = sub {
    "Beautified " . $_[0];
};
my $w3 = Test::PerlWatcher::TestWatcher->new(%watcher_init);
like $w3->describe, qr/Beautified.{2,}/, "has beautified description";

$watcher_init{inner_sub} = [ sub{;} ];
my $w4 = Test::PerlWatcher::TestWatcher->new(%watcher_init);
ok $w4->unique_id, "watcher with inner sub has an unique id";

done_testing;

