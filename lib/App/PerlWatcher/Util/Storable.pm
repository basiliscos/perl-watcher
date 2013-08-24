package App::PerlWatcher::Util::Storable;
{
  $App::PerlWatcher::Util::Storable::VERSION = '0.14';
}
# ABSTRACT: Used to freeze/thaw PerlWatcher status (watcher memories and shelf of statuses)

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Storable;

use App::PerlWatcher::Engine;
use App::PerlWatcher::Watcher;

use parent qw/Exporter/;
our @EXPORT_OK = qw/freeze thaw/;

local our %Watchers_Pool;

sub freeze {
    my ($engine) = @_;
    my %watchers_memories =
        map { $_ => $_->memory }
        @{ $engine->watchers };

    my $stored_items = {
        version           => $App::PerlWatcher::Engine::VERSION // 'dev',
        shelf             => $engine->shelf,
        watchers_memories => \%watchers_memories,
    };
    return Storable::freeze($stored_items);
}

# return true on success
sub thaw {
    my ($engine, $serialized) = @_;
    my $watchers = $engine->watchers;
    local our %Watchers_Pool;
    @Watchers_Pool{ @$watchers } = @$watchers;

    my $stored_items = eval { Storable::thaw($serialized) };
    return 0 if $@;

    my $version = $stored_items->{version} // 'dev';
    return 0
        unless $version eq ($App::PerlWatcher::Engine::VERSION // 'dev');

    my %watchers_memories = %{ $stored_items->{watchers_memories} };
    my $shelf = $stored_items->{shelf};

    my @actual_watcher_ids
        = grep { $Watchers_Pool{$_} }  keys %watchers_memories;

    $Watchers_Pool{$_}->memory($watchers_memories{$_})
        for(@actual_watcher_ids);

    my $statuses = $shelf->statuses;
    my $actual_statuses = {};
    @$actual_statuses{ @actual_watcher_ids } = @{$statuses}{ @actual_watcher_ids };
    $shelf->statuses($actual_statuses);

    $engine->shelf($shelf);
    return 1;
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Util::Storable - Used to freeze/thaw PerlWatcher status (watcher memories and shelf of statuses)

=head1 VERSION

version 0.14

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
