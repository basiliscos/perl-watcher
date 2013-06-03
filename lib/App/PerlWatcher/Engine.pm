package App::PerlWatcher::Engine;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Class::Load ':all';
use Data::Dumper;
use Devel::Comments;

sub new {
    my ( $class, $config ) = @_;
    my $backend = _construct_backend( $config );
    my $watchers = _construct_watchers( $config );
    my $watchers_order = {};
    $watchers_order->{ @{$watchers}[$_] } = $_ for 0 .. @$watchers - 1;
    my $self = {
        _backend        => $backend,
        _watchers       => $watchers,
        _watchers_order => $watchers_order,
        _statuses       => {},
        _statuses_stash => {},
        _config         => $config // {},
    };
    return bless $self, $class;
}

sub guess_frontend {
    my $self = shift;
    my $fe;
    my $loop = $self -> config -> {backend};
    my $class = "App::PerlWatcher::ui::" . $loop . "::Application"; 
    eval {
        load_class($class);
        $fe = $class -> new( $self );
        $self -> frontend( $fe );
    };
    carp "Error creating application $class : $@" if $@;
    return $fe;
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
                $self->{_statuses}->{ $status->watcher } = $status;

                my $statuses = $self->_gather_results;
                $self->{_frontend}->update($statuses);
            }
        );
    }
    $self -> {_backend} -> start_loop;
}

sub stop {
    shift -> {_backend} -> stop_loop;
}

sub stash {
    my ($self, $status) = @_;
    my $watcher = $status -> watcher;
    $self -> {_statuses_stash} -> {$watcher} = $status; 
}

sub has_changed {
    my ($self, $status) = @_;
    my $watcher = $status -> watcher;
    my $stashed_status = $self -> {_statuses_stash} -> {$watcher};
    return 1 if !defined($stashed_status);
    return $stashed_status->updated_from($status);
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

sub _gather_results {
    my $self     = shift;
    my @statuses = sort {
        my $a_index = $self->{_watchers_order}->{ $a->watcher };
        my $b_index = $self->{_watchers_order}->{ $b->watcher };
        return $a_index <=> $b_index;
    } values( %{ $self->{_statuses} } );
    return \@statuses;
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
