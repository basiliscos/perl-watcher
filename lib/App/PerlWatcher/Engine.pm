package App::PerlWatcher::Engine;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Data::Dumper;
use Devel::Comments;

sub new {
    my ( $class, $watchers, $config ) = @_;
    my $watchers_order = {};
    $watchers_order->{ @{$watchers}[$_] } = $_ for 0 .. @$watchers - 1;
    my $self = {
        _watchers       => $watchers,
        _watchers_order => $watchers_order,
        _statuses       => {},
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
    my $self     = shift;
    my $interval = 3;
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

    main Gtk2;
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

1;
