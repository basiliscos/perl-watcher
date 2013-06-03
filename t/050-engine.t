#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Gtk2;
use Devel::Comments;
use File::Basename;
use FindBin;
use Test::More; # skip_all => "not implemented yet";
use Test::HTTP::Server;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
require App::PerlWatcher::Engine;

my $config = {
    backend => 'Gtk2',
};
my $engine = App::PerlWatcher::Engine->new($config);
ok $engine;

#start/stop test
my $stopped = 0;
my $w = AnyEvent->timer (
    after => 0, 
    cb => sub {
        $engine->stop;
        $stopped = 0;
    }
);
$engine->start;

ok $stopped == 0;

done_testing();
