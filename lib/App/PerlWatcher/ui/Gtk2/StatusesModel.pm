package App::PerlWatcher::ui::Gtk2::StatusesModel;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use App::PerlWatcher::Status qw/level_to_symbol :levels/;
use Carp;
use Devel::Comments;
use List::Util qw/max/;
use Gtk2;
use POSIX qw(strftime);

use base 'Gtk2::TreeStore';

sub new {
    my ($class, $app) = @_;
    my $self = Gtk2::TreeStore->new(qw/Glib::Scalar/);
    $self -> {_watchers} = {};
    $self -> {_engine  } = $app->engine;
    bless $self, $class;
    
    for (@{ $app->engine->get_watchers }) {
        my $iter = $self->append(undef);
        my $status = $_->initial_status;
        $self -> {_watchers}{ $_ } = {
            status   =>  $status,
            iterator => $iter, 
        };
        $self -> _update_status( $iter, $status); 
    }
          
    return $self;
}

sub update {
    my ( $self, $s ) = @_;
    my $watcher_info = $self -> {_watchers}{ $s->watcher };
    my $iter = $watcher_info->{iterator};
    $self -> _update_status( $iter, $s);
    $watcher_info->{status} = $s;
}

sub get_status {
    my ( $self, $watcher ) = @_;
    return $self -> {_watchers}{ $watcher }{status};
}

sub max_actual_level {
    my $self = shift;
    my $max = max map { $_->{status}->level } 
        values %{ $self -> {_watchers} };
    
    $max //= LEVEL_ANY;
    return $max;
}

sub _update_status {
    my ($self, $iterator, $status ) = @_;
    my $label  = sprintf( "[%s] %s", $status->symbol, $status->description->() );
    $self->set( $iterator, 0 => $status );
    $self -> _update_event_items($iterator, $status);
}

sub _update_event_items {
    my ($self, $iter_parent, $status ) = @_;
    # remove all (old) children
    {
        my $child = $self ->iter_children ($iter_parent);
        while ($child) {
            my $next = $self -> iter_next($child);
            $self -> remove($child);
            $child = $next; 
        };
    }
    
    # add new children
    my $items = $status->items ? $status->items->() : [];
    for my $i (@$items) {
        my $iter_child = $self->append($iter_parent);
        $self->set( $iter_child, 0 => $i );
    }
}

1;
