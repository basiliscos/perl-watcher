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
            string_to_level
            LEVEL_NOTICE LEVEL_INFO 
            LEVEL_WARN LEVEL_ALERT
    /;
    
our %EXPORT_TAGS = (
    levels => 
        [qw(
            
            LEVEL_NOTICE LEVEL_INFO 
            LEVEL_WARN LEVEL_ALERT
        )], 
);

our %_l2s = (
    LEVEL_NOTICE()    => 'n',
    LEVEL_INFO()      => 'i',
    LEVEL_WARN()      => 'w',
    LEVEL_ALERT()     => 'A',
);


our %_l2string = (
    LEVEL_NOTICE()    => 'notice',
    LEVEL_INFO()      => 'info',
    LEVEL_WARN()      => 'warn',
    LEVEL_ALERT()     => 'alert',
);

sub string_to_level {
    my $s = shift;
    ## $s
    my %reversed = reverse %_l2string;
    my $r = $reversed{ $s };
    carp "unknown level '$s'" unless defined $r;
    return $r;
}

sub new {
    my ( $class, $watcher, $level, $description, $items ) = @_;
    
    my $self = {
        _watcher     => $watcher,
        _level       => $level,
        _description => $description,
        _items       => $items,
    };
    return bless $self, $class;
}

sub watcher {
    return shift->{_watcher};
}

sub level {
    return shift->{_level};
}

sub symbol {
    my $self = shift;
    my $r = $_l2s{ $self->{_level} };
    return $r;
}

sub description {
    return shift->{_description};
}

sub items {
    return shift->{_items};
}

1;
