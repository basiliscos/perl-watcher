package App::PerlWatcher::Watcher;

use 5.12.0;
use strict;
use warnings;

use Carp;

sub active {
    my ( $self, $value ) = @_;
    if ( defined($value) ) {
        delete $self->{_w} unless $value;
        $self->start if $value;
    }
    return defined( $self->{_w} );
}

sub description {
     croak 'Method "description" not implemented by subclass';
}

1;
