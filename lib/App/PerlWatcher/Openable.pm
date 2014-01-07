package App::PerlWatcher::Openable;
# ABSTRACT: The base role to allow item to be openable in system browser

use 5.12.0;
use strict;
use warnings;

use Carp;
use Function::Parameters qw(:strict);
use IPC::Run3;
use Moo::Role;
use Types::Standard qw/Str/;

=head1 SYNOPSIS

    Moo::Role->apply_roles_to_object($item, qw/App::PerlWatcher::Openable/);

    $item->url('http://google.com');

    $item->open_url;

=cut


=attr url

The url like https://duckduckgo.com/?q=perl

=cut

has 'url' => ( is => 'rw', isa => Str);

=method open_url

Used to open url in system browser

=cut

method open_url {
    my $url = $self->url;
    run3 [ "xdg-open", $url ]
        or carp("executing 'xdg-open $url' error: $?");
}

1;
