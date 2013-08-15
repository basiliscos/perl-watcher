package App::PerlWatcher::WatcherMemory;
{
  $App::PerlWatcher::WatcherMemory::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Carp;
use List::Util qw( max );
use Moo;

use App::PerlWatcher::Level qw/:levels/;

has 'thresholds_map'    => ( is => 'ro', required => 1);
has 'last_level'        => ( is => 'rw', default => sub { LEVEL_NOTICE; } );

sub interpret_result {
    my ($self, $result) = @_;
    my $threshold_map = $self -> thresholds_map;

    $self -> {_last_result} //= $result;
    my ($meta_key, $opposite_key)
        = $result ? ('ok',   'fail')
                  : ('fail',  'ok' );

    my $counter_key          =  "_$meta_key" . "_counter";
    my $opposite_counter_key =  "_$opposite_key" . "_counter";

    my $result_changed = $self -> {_last_result} ne $result;
    # reset values
    @$self{ ($counter_key, $opposite_counter_key) } = (0,0)
        if ($result_changed);
    my $counter = ++$self -> {$counter_key};

    my @levels = sort keys (%{ $threshold_map -> {$meta_key} });
    # @levels
    # $counter
    my $level_key = max grep { $_ <= $counter } @levels;
    # $level_key
    if ( defined $level_key ) {
        my $new_level = $threshold_map -> {$meta_key} -> {$level_key};
        $self->last_level($new_level);
    }
    $self -> {_last_result} = $result;

    return $self->last_level;
}

1;
