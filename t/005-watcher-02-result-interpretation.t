#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use FindBin;
use Test::More;

use App::PerlWatcher::Level qw/:levels/;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher;

{
    package Test::PerlWatcher::TestWatcher;
    use base qw/App::PerlWatcher::Watcher/;
    sub new {
        my ( $class, $engine_config, %config ) = @_;
        my $self = $class->SUPER::new($engine_config, %config);
        $self -> _install_thresholds($engine_config, \%config);
        return $self;
    }
    sub description { shift;  }
}

my $engine_config = {
    defaults    => {
        timeout     => 1,
        behaviour   => {
            fail => { 
                3   =>  'info',
                5   =>  'alert',
            },
            ok  => { 3 => 'notice' },
        },
    },
};

my $watcher = Test::PerlWatcher::TestWatcher->new($engine_config);
ok $watcher, "watcher has been defined";

sub expect {
    my $level = shift;
    return sub { 
        my $status = shift; 
        is $status->level, $level;
    };
}

$watcher->_interpret_result(1, expect(LEVEL_NOTICE));
$watcher->_interpret_result(1, expect(LEVEL_NOTICE));
$watcher->_interpret_result(1, expect(LEVEL_NOTICE));

$watcher->_interpret_result(0, expect(LEVEL_NOTICE));
$watcher->_interpret_result(0, expect(LEVEL_NOTICE));
$watcher->_interpret_result(0, expect(LEVEL_INFO));
$watcher->_interpret_result(0, expect(LEVEL_INFO));
$watcher->_interpret_result(0, expect(LEVEL_ALERT));
$watcher->_interpret_result(0, expect(LEVEL_ALERT));
$watcher->_interpret_result(1, expect(LEVEL_ALERT));
$watcher->_interpret_result(1, expect(LEVEL_ALERT));
$watcher->_interpret_result(1, expect(LEVEL_NOTICE));
$watcher->_interpret_result(0, expect(LEVEL_NOTICE));
$watcher->_interpret_result(0, expect(LEVEL_NOTICE));
$watcher->_interpret_result(0, expect(LEVEL_INFO));

my %specific_config = (
    fail => { 
        2   =>  'info/max',
    },
    ok  => { 1 => 'notice' },
);

$watcher = Test::PerlWatcher::TestWatcher->new($engine_config, %specific_config);
$watcher->_interpret_result(1, expect(LEVEL_NOTICE));
$watcher->_interpret_result(1, expect(LEVEL_NOTICE));
$watcher->_interpret_result(1, expect(LEVEL_NOTICE));

$watcher->_interpret_result(0, expect(LEVEL_NOTICE));
#$watcher->_interpret_result(0, expect(LEVEL_INFO));
#$watcher->_interpret_result(0, expect(LEVEL_INFO));
#$watcher->_interpret_result(0, expect(LEVEL_INFO));
#$watcher->_interpret_result(0, expect(LEVEL_INFO));
#$watcher->_interpret_result(0, expect(LEVEL_INFO));
#$watcher->_interpret_result(0, expect(LEVEL_INFO));

done_testing();

