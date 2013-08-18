package App::PerlWatcher::Openable;
# ABSTRACT: The base role to to allow item to be openable in system browser

use 5.12.0;
use strict;
use warnings;

use Carp;
use IPC::Run qw(run);
use Moo::Role;

=head1 SYNOPSIS

    Moo::Role->apply_roles_to_object($item, qw/App::PerlWatcher::Openable/);

    $item->url('http://google.com');

    $item->open_url;

=cut


=attr url

The url like https://duckduckgo.com/?q=perl

=cut

has 'url'    => ( is => 'rw');

=method open_url

Used to open url in system browser

=cut

sub open_url {
    my $self = shift;
    my $url = $self->url;
    run [ "xdg-open", $url ] 
        or carp("executing 'xdg-open $url' error: $?");
}

1;
