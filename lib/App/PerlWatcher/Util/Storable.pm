package App::PerlWatcher::Util::Storable;
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
