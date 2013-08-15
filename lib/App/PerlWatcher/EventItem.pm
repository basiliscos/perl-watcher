package App::PerlWatcher::EventItem;
{
  $App::PerlWatcher::EventItem::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Moo;

has 'content'   => ( is => 'ro', required => 1 );
has 'timestamp' => ( is => 'ro', default => sub{ time; } );

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::EventItem

=head1 VERSION

version 0.12

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
