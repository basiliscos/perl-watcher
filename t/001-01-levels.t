#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Test::More;

use App::PerlWatcher::Level qw/:levels/;

ok LEVEL_ANY    < LEVEL_NOTICE;
ok LEVEL_NOTICE < LEVEL_INFO;
ok LEVEL_INFO   < LEVEL_WARN;
ok LEVEL_WARN   < LEVEL_ALERT;
ok LEVEL_ALERT  < LEVEL_IGNORE;

like LEVEL_NOTICE, qr/notice/;
like LEVEL_INFO  , qr/info/;

done_testing();

