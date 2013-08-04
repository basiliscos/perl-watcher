package App::PerlWatcher::Shelf;
{
  $App::PerlWatcher::Shelf::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Moo;
use Scalar::Util qw/refaddr/;
use Storable;

has 'statuses'  => ( is => 'rw', default => sub { {}; } );

sub stash_status {
    my ($self, $status) = @_;
    my $same_as_previous = 0;
    if ( defined($status) ) {
        my $previous = $self->statuses->{ $status -> watcher };
        $same_as_previous = 1 
            if ( defined($previous)  
                 and refaddr($previous) == refaddr($status) );
        $self->statuses->{ $status -> watcher } = $status;
    }
    return $same_as_previous;
}

sub status_changed {
    my ($self, $status) = @_;
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

=head1 NAME

App::PerlWatcher::Shelf

=head1 VERSION

version 0.12

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
