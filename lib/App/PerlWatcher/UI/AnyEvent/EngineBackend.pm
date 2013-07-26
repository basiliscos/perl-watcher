package App::PerlWatcher::UI::AnyEvent::EngineBackend;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;

sub new {
    my $class = shift;
    my $self = {};
    return bless $self => $class;
}

sub start_loop {
    my $self = shift;
    $self->{_app_stop} = AnyEvent->condvar;
    $self->{_app_stop}->recv;
}

sub stop_loop {
    my $self = shift;
    $self->{_app_stop}->send;
}

1;
