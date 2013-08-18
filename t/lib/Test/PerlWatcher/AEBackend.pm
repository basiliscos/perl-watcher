package Test::PerlWatcher::AEBackend;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Moo;

with 'App::PerlWatcher::Backend';

has 'cv' => (is => 'ro', default => sub {AnyEvent->condvar;} );

sub start_loop {
    my $self = shift;
    $self->cv->recv;
}

sub stop_loop {
    my $self = shift;
    $self->cv->send;
}

1;
