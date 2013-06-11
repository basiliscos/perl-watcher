package App::PerlWatcher::Status;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::Comments;
use Exporter;

use constant {
    LEVEL_ANY       => 0,
    
    LEVEL_NOTICE    => 2,
    LEVEL_INFO      => 3,
    LEVEL_WARN      => 4,
    LEVEL_ALERT     => 5,
    
    LEVEL_IGNORE    => 10,
};


our @ISA = qw(Exporter);
our @EXPORT_OK = 
    qw/
            string_to_level level_to_symbol
            
            LEVEL_NOTICE LEVEL_INFO 
            LEVEL_WARN LEVEL_ALERT
            
            LEVEL_ANY LEVEL_IGNORE
    /;
    
our %EXPORT_TAGS = (
    levels => 
        [qw(
            
            LEVEL_NOTICE LEVEL_INFO 
            LEVEL_WARN LEVEL_ALERT
            
            LEVEL_ANY LEVEL_IGNORE
        )], 
);

our %_symbols_for = (
    LEVEL_ANY()       => '?',
    LEVEL_NOTICE()    => 'n',
    LEVEL_INFO()      => 'i',
    LEVEL_WARN()      => 'w',
    LEVEL_ALERT()     => 'A',
);


our %_labels_for = (
    LEVEL_ANY()       => 'unknown',
    LEVEL_NOTICE()    => 'notice',
    LEVEL_INFO()      => 'info',
    LEVEL_WARN()      => 'warn',
    LEVEL_ALERT()     => 'alert',
);

sub string_to_level {
    my $s = shift;
    ## $s
    my %reversed = reverse %_labels_for;
    my $r = $reversed{ $s };
    carp "unknown level '$s'" unless defined $r;
    return $r;
}

sub level_to_symbol {
    my $level = shift;
    return $_symbols_for{$level};
}

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

sub symbol {
    my $self = shift;
    my $r = $_symbols_for{ $self->{_level} };
    return $r;
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
    carp unless $a -> {_watcher} == $b -> {_watcher};
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
