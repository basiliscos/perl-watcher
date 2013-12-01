package Test::PerlWatcher::FrontEnd;

use Moo;

with 'App::PerlWatcher::Frontend';
has 'update_cb' => (is => 'ro');
has 'poll_cb'   => (is => 'ro');

sub update {
    my ( $self, $status ) = @_;
    $self->update_cb->($status);
}

sub poll {
    my ( $self, $status ) = @_;
    $self->poll_cb->($status);
}

1;
