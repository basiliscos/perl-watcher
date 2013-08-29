package App::PerlWatcher::Describable;
{
  $App::PerlWatcher::Describable::VERSION = '0.15';
}
# ABSTRACT: The base role for providing description for UI

use 5.12.0;
use strict;
use warnings;

use Moo::Role;


requires 'description';


requires 'start';



has 'describer' => ( is => 'ro', default => sub { return sub { $_[0]; }; }, );



sub describe {
    my $self = shift;
    return $self->describer->($self->description);
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Describable - The base role for providing description for UI

=head1 VERSION

version 0.15

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

=head2 start

Starts watcher. The parameter is callback, wich is been invoked with Status
on watched event occurence

=head2 describe

Returns the result on passing description via describer.
Means to be used in frontends

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
