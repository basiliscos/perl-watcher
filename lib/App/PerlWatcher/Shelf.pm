package App::PerlWatcher::Shelf;
# ABSTRACT: Used to stash (store) statuses for further detection weather they has been changed.

use 5.12.0;
use strict;
use warnings;

use Function::Parameters qw(:strict);
use Smart::Comments -ENV;
use Moo;
use Scalar::Util qw/refaddr/;
use Storable;
use Types::Standard qw/HashRef/;


=attr statuses

The hash ref, with key watcher (actually watcher unique id) and the value is the watchers'
status.

=cut
has 'statuses'  => ( is => 'rw', default => sub { {}; }, isa => HashRef);

=method stash_status

Stores the status. Returns true if the previous stashed value isn't the same as the provided stashed value.

=cut

method stash_status($status) {
    my $same_as_previous = 0;
    if ( defined($status) ) {
        my $previous = $self->statuses->{ $status -> watcher };
        $same_as_previous = $previous && (refaddr($previous) == refaddr($status));
        $self->statuses->{ $status -> watcher } = $status;
    }
    return $same_as_previous;
}

=method status_changed

Checks weather the provided status value differs from stashed one.
Actual logic is delegated to $status->updated_from

=cut

method status_changed($status) {
    my $watcher = $status -> watcher;
    my $stashed_status = $self->statuses->{$watcher};
    return 1 unless $stashed_status;
    my $updated = $stashed_status->updated_from($status);
    # $updated
    return $updated;
}

1;
