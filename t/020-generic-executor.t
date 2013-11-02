#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Smart::Comments;
use File::Temp qw/ tempdir /;
use List::MoreUtils qw/any none/;
use Path::Class qw/file/;
use Test::More;

use App::PerlWatcher::Levels;
use aliased qw/App::PerlWatcher::Watcher::GenericExecutor/;

my $tmp_dir = tempdir( CLEANUP => 1 );

mkdir "$tmp_dir/a" or die($@);
mkdir "$tmp_dir/b" or die($@);
my $file_database = file("$tmp_dir/a/my-database.txt");
my $file_X        = file("$tmp_dir/b/X.txt");
my $file_strage   = file("$tmp_dir/b/strange_file.txt");

$_->spew("data")
    for ($file_database, $file_X);

my $watcher;
my $end_cv = AnyEvent->condvar;

sub has_filename {
    my ($name, $items) = @_;
    my $re = qr/$name/;
    my $result = any { $_->content =~ /$re/ } @$items;
    return $result;
}

my $scenario = [
    sub {
        my $status = shift;
        my $items = $status->items->();
        is @$items, 4, "has 4 items";

        ok has_filename($file_database->basename, $items), "has database among items";
        ok has_filename($file_X->basename, $items), "has X among items";
        is $status->level, LEVEL_NOTICE, "nothing happend - notice";

        $file_strage->spew("data");
        $watcher->force_poll;
    },
    sub {
        my $status = shift;
        my $items = $status->items->();
        is @$items, 5, "has 5 items";

        ok has_filename($file_strage->basename, $items), "has strange file among items";
        is $status->level, LEVEL_WARN, "strange file - got warning";

        unlink $file_database;
        #unlink $file_strage;
        $watcher->force_poll;
    },
    sub {
        my $status = shift;
        my $items = $status->items->();
        is @$items, 4, "has 4 items";

        ok !has_filename($file_database->basename, $items), "hasn't database file among items";
        is $status->level, LEVEL_ALERT, "no database file - got alert";

        $watcher->active(0);
        $end_cv->send;
    },
];
my $invocations = 0;
my $callback_handler = sub {
    return  $scenario->[$invocations++]->(@_);
};

my $engine_config = {
    defaults    => {
        behaviour   => {
            fail => {
                3   =>  'info',
                5   =>  'alert',
            },
            ok  => { 3 => 'notice' },
        },
    },
};

my %watcher_config = (
    command       => "/bin/ls",
    arguments     => ["-1a", "$tmp_dir/a", "$tmp_dir/b"],
    timeout       => 1,
    filter        => sub { ($_ !~ /^\.{1,2}$/) && (/\S+/) },
    rules         => [
        alert => sub { none { /my-database.txt/ } @_ },
        warn  => sub { any { /strange_file.txt/ } @_ },
    ],
    engine_config => $engine_config,
    callback      => $callback_handler,
);
$watcher = GenericExecutor->new(%watcher_config);
my $w2 = GenericExecutor->new(%watcher_config);
is "$watcher", "$w2", "watchers have the same id";

$watcher->start;

$end_cv->recv;
is $invocations, @$scenario, "all screnario items has been executed";

# testing timeout
{
    my $tmp_dir = tempdir( CLEANUP => 1 );
    my $sleep_boody = <<SLEEP_END;
#!/usr/bin/env perl
sleep(5);
SLEEP_END
    my $sleep_binary = file("$tmp_dir/sleep.pl");
    $sleep_binary->spew($sleep_boody);
    chmod 0755, "$sleep_binary";
    $watcher_config{command} = "$sleep_binary";
    $watcher_config{timeout} = 1;

    my $wait_cv = AnyEvent->condvar;
    my $handled_timeout = 0;
    $watcher_config{callback} = sub {
        my $status = shift;
        $handled_timeout = 1;
        $wait_cv->send;
    };
    my $w = AnyEvent->timer(
        after => 2,
        cb    => sub { $wait_cv->send },
    );
    my $w3 = GenericExecutor->new(%watcher_config);
    $w3->start;
    $wait_cv->recv;
    ok $handled_timeout, "timeout has been handled correctly";
}

done_testing;
