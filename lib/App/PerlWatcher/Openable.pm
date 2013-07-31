package App::PerlWatcher::Openable;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Moo::Role;

has 'url'    => ( is => 'rw');

sub open_url {
    my $self = shift;
    my $url = $self->url;
    system "xdg-open", $url 
        or carp ("executing 'xdg-open $url' error: $?");
}

1;
