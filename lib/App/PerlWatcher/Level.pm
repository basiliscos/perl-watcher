package App::PerlWatcher::Level;
{
  $App::PerlWatcher::Level::VERSION = '0.16_2'; # TRIAL
}
# ABSTRACT: Represents severity with corresponding metrics e.g. level_info < level_alert

use 5.12.0;
use strict;
use warnings;

use Moo;

use overload fallback => 1,
     '0+' => sub { $_[0]->value },
     '""' => sub { $_[0]->description };


has 'value'       => ( is => 'ro', required => 1);


has 'description' => ( is => 'ro', required => 1);

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Level - Represents severity with corresponding metrics e.g. level_info < level_alert

=head1 VERSION

version 0.16_2

=head1 ATTRIBUTES

=head2 value

The numeric value (weight) of level.

=head2 description

The string desctiption of level

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
