package App::PerlWatcher::Openable;
{
  $App::PerlWatcher::Openable::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Carp;
use IPC::Run qw(run);
use Moo::Role;

has 'url'    => ( is => 'rw');

sub open_url {
    my $self = shift;
    my $url = $self->url;
    run [ "xdg-open", $url ] 
        or carp("executing 'xdg-open $url' error: $?");
}


1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Openable

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    Moo::Role->apply_roles_to_object($item, qw/App::PerlWatcher::Openable/);

    $item->url('http://google.com');

    $item->open_url;

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
