#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Test::More;

use App::PerlWatcher::Level qw/:levels/;
use App::PerlWatcher::Status;
use App::PerlWatcher::Shelf;

{
    package Test::PerlWatcher::TestWatcher;
    use Moo;
    with qw/App::PerlWatcher::Watcher/;
    sub description { shift;  }
}

my $watcher = Test::PerlWatcher::TestWatcher->new(engine_config=>{});

my $create_status = sub {
    my $level = shift;
    return App::PerlWatcher::Status->new(
        level           => $level,
        watcher         => $watcher,
    );                               
};
                                                   
my $shelf = App::PerlWatcher::Shelf->new;

my $s1 = $create_status->(LEVEL_NOTICE);

ok $shelf -> status_changed($s1);
ok $shelf -> status_changed($s1);
ok !$shelf -> stash_status($s1);
ok $shelf -> stash_status($s1);
ok !$shelf -> status_changed($s1);

my $s2 = $create_status->(LEVEL_NOTICE);
ok !$shelf -> status_changed($s2);

my $s3 = $create_status->(LEVEL_INFO);
ok $shelf -> status_changed($s3);

done_testing();

