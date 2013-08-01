package App::PerlWatcher::Openable;
{
  $App::PerlWatcher::Openable::VERSION = '0.12';
}

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

=head1 SYNOPSIS

    Moo::Role->apply_roles_to_object($item, qw/App::PerlWatcher::Openable/);

    $item->url('http://google.com');

    $item->open_url;

=cut

1;
