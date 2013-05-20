package App::PerlWatcher::Status;

use 5.12.0;
use strict;
use warnings;

use Data::Dumper;

our $RESULT_OK    = "result.ok";
our $RESULT_FAIL  = "result.fail";
our $LEVEL_NOTICE = "level.notice";
our $LEVEL_ALERT  = "level.alert";

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
        $self->{_level} eq $App::PerlWatcher::Status::LEVEL_ALERT  ? '!'
      : $self->{_result} eq $App::PerlWatcher::Status::RESULT_FAIL ? '?'
      :                                                              'ok';
    return $r;
}

sub description {
    return shift->{_description};
}

sub items {
    return shift->{_items};
}

1;
