package App::PerlWatcher::ui::Gtk2::StatusesModel;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/level_to_symbol :levels/;
use Devel::Comments;
use List::Util qw/max/;
use Gtk2;
use POSIX qw(strftime);

use base 'Gtk2::TreeStore';

sub new {
    my $class = shift;
    my $self = Gtk2::TreeStore->new(qw/Glib::Scalar/);
    $self -> {_statuses} = [];
    bless $self, $class;
    return $self;
}

sub update {
    my ( $self, $statuses ) = @_;
    $self->clear;
    
    for (@$statuses) {
        my $iter   = $self->append(undef);
        my $label  = sprintf( "[%s] %s", $_->symbol, $_->description->() );
        my $active = $_->watcher->active;
        $self->set( $iter, 0 => $_ );
        my $items = $_->items ? $_->items->() : [];
        for my $i (@$items) {
            my $iter_child = $self->append($iter);
            $self->set( $iter_child, 0 => $i );
        }
    }
    $self -> {_statuses} = $statuses;
}

sub max_actual_level {
    my $self = shift;
    my $max = max map { $_->level } @{ $self -> {_statuses} };
    $max //= LEVEL_ANY;
}

1;
