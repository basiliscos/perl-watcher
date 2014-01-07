package App::PerlWatcher::Describable;
{
  $App::PerlWatcher::Describable::VERSION = '0.20';
}
# ABSTRACT: The base role for providing description for UI

use 5.12.0;
use strict;
use warnings;

use Function::Parameters qw(:strict);
use Moo::Role;
use Types::Standard qw/CodeRef/;


requires 'description';


has 'describer' => (
    is      => 'ro',
    default => sub { return sub { $_[0]; }; },
    isa     => CodeRef,
);



method describe {
    return $self->describer->($self->description);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Describable - The base role for providing description for UI

=head1 VERSION

version 0.20

=head1 ATTRIBUTES

=head2 describer

The subroutine, which takes description as an string, and allows
to do with it something funny, e.g. add "location" in label for
weather-watcher:

   describer   => sub { "Weather in Minsk: " . $_[0] },

Default value: sub, which just returns it's value. The describer
means to be provided by user configs.

=head1 METHODS

=head2 description

The string description, it means to be provided by developer, e.g. watcher
developer

=head2 describe

Returns the result on passing description via describer.
Means to be used in frontends

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
