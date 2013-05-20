package App::PerlWatcher::Watcher;

use 5.12.0;
use strict;
use warnings;

sub active {
    my ( $self, $value ) = @_;
    if ( defined($value) ) {
        delete $self->{_w} unless $value;
        $self->start if $value;
    }
    return defined( $self->{_w} );
}

1;
