package App::PerlWatcher::Frontend;
{
  $App::PerlWatcher::Frontend::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Carp;

sub new {
    my ( $class, $engine ) = @_;
    my $self = {
        _engine     => $engine,
        _last_seen  => 0, 
    };
    bless $self, $class;
}

sub update {
    my ( $self, $status ) = @_;
    croak 'Method "show" not implemented by subclass';
}

sub show {
     croak 'Method "show" not implemented by subclass';
}

sub last_seen {
    my ($self, $time) = @_;
    $self -> {_last_seen} = $time if ( defined $time );
    return $self -> {_last_seen};
}

sub engine {
    return shift -> {_engine};
}

1;
