package Test::PerlWatcher::FrontEnd;

use Moo;

with 'App::PerlWatcher::Frontend';
has 'cb'    => (is => 'ro');

sub update {
    my ( $self, $status ) = @_;
    $self->cb->($status);
}

1;
