package App::PerlWatcher::Level;
{
  $App::PerlWatcher::Level::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Carp;

use parent qw/Exporter/;

use overload fallback => 1,
     '0+' => 'value',
     '""' => 'stringify';

sub value {
    return shift->{_value};
}

sub stringify {
    return shift->{_description};
}

our %_INSTANCE_FOR;

sub _new {
    my ($class, $value, $description) = @_;
    my $self = {
        _value       => $value,
        _description => $description,
    };
    bless $self => $class;

    $_INSTANCE_FOR{$description} = $self;

    return $self;
}

sub get_by_description {
    my $description = shift;
    my $level = $_INSTANCE_FOR{$description};
    carp "unknown level '$description'"
        unless $level;
    return $level;
}

use constant {
    LEVEL_ANY       => __PACKAGE__->_new(0, 'unknown'),

    LEVEL_NOTICE    => __PACKAGE__->_new(2, 'notice'),
    LEVEL_INFO      => __PACKAGE__->_new(3, 'info'),
    LEVEL_WARN      => __PACKAGE__->_new(4, 'warn'),
    LEVEL_ALERT     => __PACKAGE__->_new(5, 'alert'),

    LEVEL_IGNORE    => __PACKAGE__->_new(10, 'ignore'),
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

our @EXPORT_OK = (qw/get_by_description/, @all_levels_strings);

our %EXPORT_TAGS = (
    levels => [ @all_levels_strings ],
);

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Level

=head1 VERSION

version 0.12

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
