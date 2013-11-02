package App::PerlWatcher::Levels;
{
  $App::PerlWatcher::Levels::VERSION = '0.16_5';
}
# ABSTRACT: Creates constants pool for all available levels for application

use 5.12.0;
use strict;
use warnings;

use Carp;
use Exporter;

use App::PerlWatcher::Level;

use parent qw/Exporter/;

our %_INSTANCE_FOR;


sub _create {
    my ($level_value, $level_description) = @_;
    my $level = App::PerlWatcher::Level->new(
        value       => $level_value,
        description => $level_description,
    );
    $_INSTANCE_FOR{$level_description} = $level;
    return $level;
}

sub get_by_description {
    my $description = shift;
    my $level = $_INSTANCE_FOR{$description};
    carp "unknown level '$description'"
        unless $level;
    return $level;
}

use constant {
     LEVEL_ANY       => _create(0, 'unknown'),

     LEVEL_NOTICE    => _create(2, 'notice'),
     LEVEL_INFO      => _create(3, 'info'),
     LEVEL_WARN      => _create(4, 'warn'),
     LEVEL_ALERT     => _create(5, 'alert'),
     LEVEL_IGNORE    => _create(10, 'ignore'),
};

our @ALL_LEVELS = (
    LEVEL_ANY,

    LEVEL_NOTICE,
    LEVEL_INFO,
    LEVEL_WARN,
    LEVEL_ALERT,

    LEVEL_IGNORE,
);

my @all_levels_strings = qw
    /
        LEVEL_ANY

        LEVEL_NOTICE
        LEVEL_INFO
        LEVEL_WARN
        LEVEL_ALERT

        LEVEL_IGNORE
    /;

our @EXPORT = (qw/get_by_description/, @all_levels_strings);

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Levels - Creates constants pool for all available levels for application

=head1 VERSION

version 0.16_5

=head1 SYNOPSIS
 use App::PerlWatcher::Levels;

 say (
    LEVEL_ANY,
    LEVEL_NOTICE,
    LEVEL_INFO,
    LEVEL_WARN,
    LEVEL_ALERT,
    LEVEL_IGNORE,
 );

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
