#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use File::Temp qw/ tempdir /;
use Test::More;
use Test::Warnings;

use_ok 'App::PerlWatcher::Util::Bootstrap';
use App::PerlWatcher::Util::Bootstrap qw/engine_config/;

$ENV{HOME} = tempdir( CLEANUP => 1 );

my $config = engine_config;
ok $config, "we've got default config";

done_testing;

