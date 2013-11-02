#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Smart::Comments;
use IO::Socket::INET;
use File::Basename;
use File::Temp qw/ tempdir /;
use List::Util qw/first/;
use Test::More;
use Test::TCP;

use aliased 'App::PerlWatcher::Engine';
use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Util::Bootstrap qw/config/;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib" }
use aliased qw/Test::PerlWatcher::AEBackend/;

$ENV{'HOME'} = tempdir( CLEANUP => 1 );
my $tmp_dir  = tempdir( CLEANUP => 1 );

my $config_path = dirname(__FILE__) . "/../share/examples/engine.conf.example";
my $config = config($config_path);
my $backend = AEBackend->new;

# hack for generic executor: there is no warranty that
# nothing changed for watching /tmp
my $ge_config = first { $_->{class} =~ /GenericExecutor/  }
    @{ $config->{watchers} };
ok $ge_config, "configuration for generic executor has been found";
$ge_config->{config}->{arguments} = ["-1a", "$tmp_dir"];

my $engine = Engine->new(config => $config, backend => $backend);
ok $engine;

my $shelf = $engine->shelf;
my $statuses = [];

for my $w ( @{ $engine->watchers } ) {
    my $status = App::PerlWatcher::Status->new(
        watcher     =>  $w,
        level       => LEVEL_INFO,
        description => sub { return $w->description; },
    );
    push @$statuses, $status;
    $shelf->stash_status($status);
}

my $serialized = freeze($engine);

$engine = Engine->new(config => $config, backend => $backend);
ok thaw($engine, $serialized);
my $thawed_shelf = $engine->shelf;

for ( @$statuses ) {
    ok $thawed_shelf->statuses->{$_->watcher}, "has status for watcher " . $_->watcher;
    ok !$thawed_shelf->status_changed($_), "status hasn't changes for " . $_->watcher ;
}

done_testing();
