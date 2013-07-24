package App::PerlWatcher::WatcherMemory;
{
  $App::PerlWatcher::WatcherMemory::VERSION = '0.10';
}

use 5.12.0;
use strict;
use warnings;

use Carp;
use List::Util qw( max );

use App::PerlWatcher::Level qw/:levels/;

sub new {
    my ($class, $threshold_map) = @_;
    
    croak "Threshold_map hasn't been defined" 
        unless $threshold_map;
    
    my $self = {_threshold_map => $threshold_map};
    bless $self => $class;
    
    return $self;
}


sub interpret_result {
    my ($self, $result) = @_;
    my $threshold_map = $self -> {_threshold_map};
    
    $self -> {_last_result} //= $result;
    my ($meta_key, $opposite_key) 
        = $result ? ('ok',   'fail')
                  : ('fail',  'ok' );
                  
    my $counter_key          =  "_$meta_key" . "_counter";
    my $opposite_counter_key =  "_$opposite_key" . "_counter";
    
    my $result_changed = $self -> {_last_result} != $result; 
    # reset values
    @$self{ ($counter_key, $opposite_counter_key) } = (0,0)
        if ($result_changed);
    my $counter = ++$self -> {$counter_key};
    
    $self -> {_last_level} //= LEVEL_NOTICE;
    
    my @levels = sort keys (%{ $threshold_map -> {$meta_key} });
    # @levels
    # $counter
    my $level_key = max grep { $_ <= $counter } @levels;
    # $level_key
    if ( defined $level_key ) {
        my $new_level = $threshold_map -> {$meta_key} -> {$level_key};
        $self -> {_last_level} = $new_level; 
    }
    $self -> {_last_result} = $result;
    
    return $self -> {_last_level};
}

sub last_level {
    return shift->{_last_level};
}

1;
