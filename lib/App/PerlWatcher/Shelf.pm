package App::PerlWatcher::Shelf;

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;
use Scalar::Util qw/refaddr/;
use Storable;

use App::PerlWatcher::Engine;

use parent qw/Exporter/;
our @EXPORT_OK = qw/thaw/;

sub new {
    my $class = shift;
    my $self = {
        _statuses => {},
    };
    return bless $self, $class;
}
                                                       
sub stash_status {
    my ($self, $status) = @_;
    my $same_as_previous = 0;
    if ( defined($status) ) {
        my $previous = $self -> {_statuses} -> { $status -> watcher };
        $same_as_previous = 1 
            if ( defined($previous)  
                 and refaddr($previous) == refaddr($status) );
        $self -> {_statuses} -> { $status -> watcher } = $status;
    }
    return $same_as_previous;
}

sub status_changed {
    my ($self, $status) = @_;
    my $watcher = $status -> watcher;
    my $stashed_status = $self -> {_statuses} -> {$watcher};
    return 1 if !defined($stashed_status);
    return $stashed_status->updated_from($status);
}

sub freeze {
    my ($self, $engine) = @_;
    local *App::PerlWatcher::Watcher::STORABLE_freeze = sub {
        my ($self, $cloning) = @_;
        return $self->unique_id;
    };
    my %watchers_memories = 
        map { $_ => $_->memory }
        @{ $engine->get_watchers };
        
    my $stored_items = {
        version           => $App::PerlWatcher::Engine::VERSION // 'dev',
        shelf             => $self,
        watchers_memories => \%watchers_memories,
    };
    return Storable::freeze($stored_items);
}

sub thaw {
    my ($serialized, $engine) = @_;
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
    
    my $stored_items = Storable::thaw($serialized);
    my $version = $stored_items->{version} // 'dev';
    return App::PerlWatcher::Shelf->new
        unless $version eq ($App::PerlWatcher::Engine::VERSION // 'dev');
    
    my $self = $stored_items->{shelf};
    my $statuses = $self->{_statuses};
    my @actual_statuses_keys
        = grep { $watchers_pool{$_} }  keys %$statuses;
    my $actual_statuses = {};
    @$actual_statuses{ @actual_statuses_keys } = values %$statuses;
    $self->{_statuses} = $actual_statuses;
    return $self;
}

1;
