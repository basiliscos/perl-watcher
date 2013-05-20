package App::PerlWatcher::Status;

use 5.12.0;
use strict;
use warnings;

use Data::Dumper;
use Devel::Comments;
use Exporter;

use constant {
    LEVEL_NOTICE    => 2,
    LEVEL_INFO      => 3,
    LEVEL_WARN      => 4,
    LEVEL_ALERT     => 5,
    RESULT_OK       => 200,
    RESULT_FAIL     => 500,
};


our @ISA = qw(Exporter);
our @EXPORT_OK = 
    qw/
            LEVEL_NOTICE LEVEL_INFO 
            LEVEL_WARN LEVEL_ALERT
            RESULT_OK RESULT_FAIL 
    /;
    
our %EXPORT_TAGS = (
    levels => 
        [qw(
            LEVEL_NOTICE LEVEL_INFO 
            LEVEL_WARN LEVEL_ALERT
        )], 
    results => 
        [qw(
            RESULT_OK RESULT_FAIL 
        )],
);


sub new {
    my ( $class, $watcher, $result, $level, $description, $items ) = @_;
    
    my $self = {
        _watcher     => $watcher,
        _result      => $result,
        _level       => $level,
        _description => $description,
        _items       => $items,
    };
    return bless $self, $class;
}

sub result {
    return shift->{_result};
}

sub watcher {
    return shift->{_watcher};
}

sub level {
    return shift->{_level};
}

sub symbol {
    my $self = shift;
    my $r =
        $self->{_level} == LEVEL_ALERT  ? '!'
      : $self->{_result} == RESULT_FAIL ? '?' : 'ok'
      ;
    return $r;
}

sub description {
    return shift->{_description};
}

sub items {
    return shift->{_items};
}

1;
