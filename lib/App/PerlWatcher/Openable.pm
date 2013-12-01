package App::PerlWatcher::Openable;
{
  $App::PerlWatcher::Openable::VERSION = '0.18_2'; # TRIAL
}
# ABSTRACT: The base role to to allow item to be openable in system browser

use 5.12.0;
use strict;
use warnings;

use Carp;
use IPC::Run3;
use Moo::Role;




has 'url'    => ( is => 'rw');


sub open_url {
    my $self = shift;
    my $url = $self->url;
    run3 [ "xdg-open", $url ] 
        or carp("executing 'xdg-open $url' error: $?");
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Openable - The base role to to allow item to be openable in system browser

=head1 VERSION

version 0.18_2

=head1 SYNOPSIS

    Moo::Role->apply_roles_to_object($item, qw/App::PerlWatcher::Openable/);

    $item->url('http://google.com');

    $item->open_url;

=head1 ATTRIBUTES

=head2 url

The url like https://duckduckgo.com/?q=perl

=head1 METHODS

=head2 open_url

Used to open url in system browser

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
