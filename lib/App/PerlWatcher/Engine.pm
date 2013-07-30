package App::PerlWatcher::Engine;
{
  $App::PerlWatcher::Engine::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Class::Load ':all';
use Data::Dumper;
use Devel::Comments;
use File::Spec;
use Path::Class qw(file);

use App::PerlWatcher::Shelf;
use App::PerlWatcher::Util::Bootstrap qw/get_home_dir/;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;

sub new {
    my ( $class, $config, $backend_id ) = @_;
    my $backend = _construct_backend( $backend_id );
    my $watchers = _construct_watchers( $config );
    my $watchers_order = {};
    $watchers_order->{ $watchers->[$_] } = $_ for 0 .. @$watchers - 1;
    my $self = {
        _backend        => $backend,
        _watchers       => $watchers,
        _watchers_order => $watchers_order,
        _config         => $config // {},
    };
    bless $self => $class;
    $self->{_shelf} = $self->_construct_shelf;
    
    return $self;
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
    my $self = shift;
    $self->{_backend}->stop_loop;
    
    my $data = freeze($self);
    my $statuses_file = $self->_statuses_file;
    $statuses_file->spew($data);
}

sub get_watchers {
    return shift->{_watchers};
}

sub statuses_shelf {
    my ($self, $value) = @_;
    $self -> {_shelf} = $value if defined($value);
    return $self -> {_shelf};
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

# private API

sub _construct_backend {
    my $backend_id = shift; 
    my $backend_class = 'App::PerlWatcher::UI::' . $backend_id . '::EngineBackend';
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
            $watcher = $class->new( engine_config => $config, %$watcher_config );
            push @r, $watcher;
        };
        carp "Error creating watcher $class : $@" if $@;
    }
    return \@r;
}

sub _statuses_file {
    my $path = File::Spec->catfile(get_home_dir(), "statuses-shelf.data");
    return file($path);
}

sub _construct_shelf {
    my $self = shift;
    my $statuses_file = _statuses_file;
    if ( -r $statuses_file ) {
        my $data = $statuses_file->slurp;
        thaw($self, $data) 
            and return $self->statuses_shelf; 
    } 
    return App::PerlWatcher::Shelf->new;
}

1;
