package App::PerlWatcher::Util::Storable;

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Storable;

use App::PerlWatcher::Engine;
use App::PerlWatcher::Watcher;

use parent qw/Exporter/;
our @EXPORT_OK = qw/freeze thaw/;

sub freeze {
    my ($engine) = @_;
    local *App::PerlWatcher::Watcher::STORABLE_freeze = sub {
        my ($self, $cloning) = @_;
        return $self->unique_id;
    };
    my %watchers_memories = 
        map { $_ => $_->memory }
        @{ $engine->get_watchers };
        
    my $stored_items = {
        version           => $App::PerlWatcher::Engine::VERSION // 'dev',
        shelf             => $engine->statuses_shelf,
        watchers_memories => \%watchers_memories,
    };
    return Storable::freeze($stored_items);
}

# return true on success
sub thaw {
    my ($engine, $serialized) = @_;
    my $watchers = $engine->get_watchers;
    my %watchers_pool;
    @watchers_pool{ @$watchers } = @$watchers;
    
    local *App::PerlWatcher::Watcher::STORABLE_attach = sub {
        my ($class, $cloning, $serialized) = @_;
        my $id = $serialized;
        my $w = $watchers_pool{$id};
        
        # we are forced to return dummy App::PerlWatcher::Watcher
        # it will be filtered later
        unless($w){
           $w = { _unique_id => 'dummy-id'};
           bless $w => $class;
        }
        return $w;
    };
    
    my $stored_items = eval { Storable::thaw($serialized) };
    return 0 if $@;
    
    my $version = $stored_items->{version} // 'dev';
    return 0
        unless $version eq ($App::PerlWatcher::Engine::VERSION // 'dev');
    
    my %watchers_memories = %{ $stored_items->{watchers_memories} };
    my $shelf = $stored_items->{shelf};

    my @actual_watcher_ids
        = grep { $watchers_pool{$_} }  keys %watchers_memories;

    $watchers_pool{$_}->memory($watchers_memories{$_}) 
        for(@actual_watcher_ids);
        
    my $statuses = $shelf->statuses;
    my $actual_statuses = {};
    @$actual_statuses{ @actual_watcher_ids } = @{$statuses}{ @actual_watcher_ids };
    $shelf->statuses($actual_statuses);
    
     
    $engine->statuses_shelf($shelf);
    return 1;
}

1;
