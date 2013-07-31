#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Devel::Comments;
use IO::Socket::INET;
use File::Basename;
use File::Temp qw/ tempdir /;
use Test::More;
use Test::TCP;

use App::PerlWatcher::Engine;
use App::PerlWatcher::Level qw/:levels/;
use App::PerlWatcher::Status;
use App::PerlWatcher::Util::Bootstrap qw/config/;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;

$ENV{'HOME'} = tempdir( CLEANUP => 1 );

my $config_path = dirname(__FILE__) . "/../share/examples/engine.conf.example";
my $config = config($config_path);
my $engine = App::PerlWatcher::Engine->new($config, 'AnyEvent');
ok $engine;

my $shelf = $engine->statuses_shelf;
my $statuses = [];

for my $w ( @{ $engine->get_watchers } ) {
    my $status = App::PerlWatcher::Status->new(
        watcher     =>  $w,
        level       => LEVEL_INFO,
        description => sub { return $w->description; },
    );
    push @$statuses, $status;
    $shelf->stash_status($status);
}

my $serialized = freeze($engine);

$engine = App::PerlWatcher::Engine->new($config, 'AnyEvent');
ok thaw($engine, $serialized);
my $thawed_shelf = $engine->statuses_shelf;

for ( @$statuses ) {
    ok !$thawed_shelf -> status_changed($_);
}


done_testing();
