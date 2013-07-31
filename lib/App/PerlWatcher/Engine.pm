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
use Moo;
use Path::Class qw(file);

use App::PerlWatcher::Shelf;
use App::PerlWatcher::Util::Bootstrap qw/get_home_dir/;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;

has 'frontend'          => ( is => 'ro', required => 0);
has 'config'            => ( is => 'ro', required => 0);
has 'backend_id'        => ( is => 'ro', required => 1);
has 'statuses_file'     => ( is => 'ro', default => sub {
        return file(File::Spec->catfile(get_home_dir(), "statuses-shelf.data"));
    });
has 'backend'           => ( is => 'lazy');
has 'watchers'          => ( is => 'lazy');
has 'watchers_order'    => ( is => 'lazy');
has 'shelf'             => ( is => 'rw');

sub _build_backend {
    my $backend_id = shift->backend_id; 
    my $backend_class = 'App::PerlWatcher::UI::' . $backend_id . '::EngineBackend';
    my $backend;                 
    eval {
        load_class($backend_class);
        $backend = $backend_class -> new;
    };
    croak "Unable to construct backend : $@" if($@);
    return $backend;
}

sub _build_watchers {
    my $self = shift;
    my $config = $self->config;
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

sub _build_watchers_order {
    my $self = shift;
    my $watchers = $self->watchers;
    my $order = {};
    $order->{ $watchers->[$_] } = $_ for 0 .. @$watchers - 1;
    return $order;
}

sub _build_shelf {
    my $self = shift;
    my $statuses_file = $self->statuses_file;
    if ( -r $statuses_file ) {
        my $data = $statuses_file->slurp;
        thaw($self, $data) 
            and return $self->shelf; 
    } 
    return App::PerlWatcher::Shelf->new;
}

sub BUILD {
    my $self = shift;
    $self->shelf($self->_build_shelf);
}

sub start {
    my $self = shift;
    for my $w ( @{ $self->watchers } ) {
        $w->start(
            sub {
                my $status = shift;
                AnyEvent::postpone {
                    $self->frontend->update($status);
                };
            }
        );
    }
    # actually trigger watchers
    $self->backend->start_loop;
}

sub stop {
    my $self = shift;
    $self->backend->stop_loop;
    
    my $data = freeze($self);
    $self->statuses_file->spew($data);
}

sub sort_statuses {
    my ($self, $statuses) = @_;
    my $order_of = $self->watchers_order;
    return [
        sort {
            $order_of->{ $a->watcher } <=> $order_of->{ $b->watcher };
        } @$statuses
    ];
}

1;
