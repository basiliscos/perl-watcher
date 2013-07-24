package App::PerlWatcher::Shelf;
{
  $App::PerlWatcher::Shelf::VERSION = '0.10';
}

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Scalar::Util qw/refaddr/;
use Storable;

sub new {
    my $class = shift;
    my $self = {
        _statuses => {},
    };
    return bless $self, $class;
}
                                                       
sub stash_status {
    my ($self, $status) = @_;
    my $same_as_previous = 0;
    if ( defined($status) ) {
        my $previous = $self -> {_statuses} -> { $status -> watcher };
        $same_as_previous = 1 
            if ( defined($previous)  
                 and refaddr($previous) == refaddr($status) );
        $self -> {_statuses} -> { $status -> watcher } = $status;
    }
    return $same_as_previous;
}

sub status_changed {
    my ($self, $status) = @_;
    my $watcher = $status -> watcher;
    my $stashed_status = $self -> {_statuses} -> {$watcher};
    return 1 unless $stashed_status;
    my $updated = $stashed_status->updated_from($status);
    # $updated
    return $updated;
}

sub statuses {
    my ($self, $value) = @_;
    $self -> {_statuses} = $value if defined($value);
    return $self -> {_statuses};
}



1;
