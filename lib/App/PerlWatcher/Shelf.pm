package App::PerlWatcher::Shelf;
{
  $App::PerlWatcher::Shelf::VERSION = '0.20';
}
# ABSTRACT: Used to stash (store) statuses for further detection weather they has been changed.

use 5.12.0;
use strict;
use warnings;

use Function::Parameters qw(:strict);
use Smart::Comments -ENV;
use Moo;
use Scalar::Util qw/refaddr/;
use Storable;

has 'statuses'  => ( is => 'rw', default => sub { {}; } );


method stash_status($status) {
    my $same_as_previous = 0;
    if ( defined($status) ) {
        my $previous = $self->statuses->{ $status -> watcher };
        $same_as_previous = $previous && (refaddr($previous) == refaddr($status));
        $self->statuses->{ $status -> watcher } = $status;
    }
    return $same_as_previous;
}


method status_changed($status) {
    my $watcher = $status -> watcher;
    my $stashed_status = $self->statuses->{$watcher};
    return 1 unless $stashed_status;
    my $updated = $stashed_status->updated_from($status);
    # $updated
    return $updated;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Shelf - Used to stash (store) statuses for further detection weather they has been changed.

=head1 VERSION

version 0.20

=head1 ATTRIBUTES

=head2 statuses

The hash ref, with key watcher (actually watcher unique id) and the value is the watchers'
status.

=head1 METHODS

=head2 stash_status

Stores the status. Returns true if the previous stashed value isn't the same as the provided stashed value.

=head2 status_changed

Checks weather the provided status value differs from stashed one.
Actual logic is delegated to $status->updated_from

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
