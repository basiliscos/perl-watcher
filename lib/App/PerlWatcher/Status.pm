package App::PerlWatcher::Status;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::Comments;

use App::PerlWatcher::Level;

sub new {
    my ( $class, %args ) = @_;
    
    my $self = {
        _watcher            => $args{watcher            },
        _level              => $args{level              },
        _description        => $args{description        },
        _items              => $args{items              },
        _timestamp          => $args{timestamp          } // time,
        _update_detector    => \&_chage_detector,
    };
    return bless $self, $class;
}

sub updated_from {
    my ($a, $b) = @_;
    return $a -> {_update_detector}->($a, $b);
}

sub watcher {
    return shift->{_watcher};
}

sub level {
    return shift->{_level};
}

sub description {
    return shift->{_description};
}

sub items {
    my ($self, $value) = @_;
    $self -> {_items} = $value if defined($value);
    return $self -> {_items};
}

sub timestamp {
    return shift->{_timestamp};
}

sub _chage_detector {
    my ($a, $b) = @_;
    carp unless $a -> {_watcher} eq $b -> {_watcher};
    return ($a->level != $b->level)
        || (defined($a->items) && !defined($b->items))
        || (!defined($a->items) && defined($b->items))
        || (defined($a->items) && defined($b->items) 
                && _items_change_detector($a->items->(), $b->items->()) 
            );
}

sub _equals_items {
    my ($a, $b) = @_;
    # $a
    # $b
    my $result = !( ($a->content cmp $b->content) || ($a->timestamp <=> $b->timestamp) );
    # $result
    return $result; 
}

sub _items_change_detector {
    my ($a, $b) = @_;
    # $a
    # $b
    return 1 if(@$a != @$b);
    for my $i (0..@$a-1) {
        return 1 
            if ! _equals_items(
                @{ $a }[$i],
                @{ $b }[$i],
            );
    }
    return 0;
}


1;
