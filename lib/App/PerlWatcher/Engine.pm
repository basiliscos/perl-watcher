package App::PerlWatcher::Engine;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Class::Load ':all';
use Data::Dumper;
use Devel::Comments;

our $VERSION = '0.06';

sub new {
    my ( $class, $config ) = @_;
    my $backend = _construct_backend( $config );
    my $watchers = _construct_watchers( $config );
    my $watchers_order = {};
    $watchers_order->{ $watchers->[$_] } = $_ for 0 .. @$watchers - 1;
    my $self = {
        _backend        => $backend,
        _watchers       => $watchers,
        _watchers_order => $watchers_order,
        _config         => $config // {},
    };
    return bless $self, $class;
}

sub frontend {
    my ( $self, $frontend ) = @_;
    $self->{_frontend} = $frontend;
}

sub config {
    return shift->{_config};
}

sub start {
    my $self = shift;
    for my $w ( @{ $self->{_watchers} } ) {
        $w->start(
            sub {
                my $status = shift;
                AnyEvent::postpone {
                    $self->{_frontend}->update($status);
                };
            }
        );
    }
    # actually trigger watchers
    $self -> {_backend} -> start_loop;
}

sub stop {
    shift -> {_backend} -> stop_loop;
}

sub get_watchers {
    return shift->{_watchers};
}

sub sort_statuses {
    my ($self, $statuses) = @_;
    my $order_of = $self->{_watchers_order};
    return [
        sort {
            $order_of->{ $a->watcher } <=> $order_of->{ $b->watcher };
        } @$statuses
    ];
}

sub _construct_backend {
    my ($config) = @_;
    my $backend_id = $config -> {backend}; 
    my $backend_class = 'App::PerlWatcher::ui::' . $backend_id . '::EngineBackend';
    my $backend;
    eval {
        load_class($backend_class);
        $backend = $backend_class -> new;
    };
    croak "Unable to construct backend : $@" if($@);
    return $backend;
}

sub _construct_watchers {
    my $config = shift;
    my @r;
    for my $watcher_definition ( @{ $config -> {watchers} } ) {
        my ($class, $watcher_config ) 
            = @{ $watcher_definition }{ qw/class config/ };
        my $watcher;
        eval {
            load_class($class);
            $watcher = $class -> new( $config, %$watcher_config );
            push @r, $watcher;
        };
        carp "Error creating watcher $class : $@" if $@;
    }
    return \@r;
}

1;
