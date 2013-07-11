#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use FindBin;
use Test::More;

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
my %engine_config;
my %watcher_config = (a=>'b', c=>1, e=>{d=>5});
my $w1 = Test::PerlWatcher::TestWatcher->new( \%engine_config, %watcher_config); 
my $w1_1 = Test::PerlWatcher::TestWatcher->new( \%engine_config, %watcher_config); 

is $w1->unique_id, $w1_1->unique_id, "different watcher instances have the same id with the same configs";

$watcher_config{c} = 2;
my $w2 = Test::PerlWatcher::TestWatcher->new( \%engine_config, %watcher_config);
ok !($w1->unique_id eq $w2->unique_id), "different watcher instances have the different configs don't have the same ids";

done_testing();

