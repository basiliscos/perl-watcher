#!/usr/bin/env perl

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::HTTPD;
use Devel::Comments;
use File::Basename;
use Path::Class qw(file); 
use Test::More;

use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher::Weather;

my $b = 0;
my $server;

sub getWeather {
    my $file = file(dirname(__FILE__) . "/data/yr.no-locationforecast.xml");
    return scalar $file->slurp(iomode => '<:encoding(UTF-8)');
}


my $end_var = AnyEvent->condvar;

my $scenario = [
    #1 
    {
        req =>  \&getWeather,
        res =>  sub {
            my $status = shift;
            # $status
            
            is $status->level, LEVEL_NOTICE;
            like $status->description->(), qr/15.7/;
            
            $end_var->send;
        },
    },
    
];

my ($server_invocations, $callback_invocations) = (0, 0);

my $result_handler = sub {
    return (split(/,/, $_))[1] unless $callback_invocations;
    die("error");
};

my $server_handler = sub {       
    return  $scenario->[$server_invocations++]->{req}->();
};
my $callback_handler = sub {
    return $scenario->[$callback_invocations++]->{res}->(@_);
};

$server = AnyEvent::HTTPD->new;
ok defined($server), "served defined";

$server->reg_cb (
    '/weather' => sub {
        my ($httpd, $req) = @_;
        $req->respond (
            { content => 
                [
                    'text/html',
                    $server_handler->()
                ]
            },
        );
    },
);

my $url = "http://" . $server->host . ":" . $server->port . "/weather";

my $engine_config = {
    defaults    => {
        behaviour   => {
            fail => { 
                1   =>  'alert',
            },
            ok  => { 3 => 'notice' },
        },
    },
};

my $watcher = App::PerlWatcher::Watcher::Weather->new(
    latitude            => 53.54,
    longitude           => 27.34,
    url_generator       => sub { return $url},
    frequency           => 10,
    on                  => { 
        ok      => { 1  => 'notice' },
        fail    => { 2 => 'info'   },
    },
    engine_config       => $engine_config,
);

ok defined($watcher), "watcher was created";

$watcher->start($callback_handler);
$end_var->recv;

is $callback_invocations, scalar @$scenario, "correct number of callback invocations";

done_testing();

