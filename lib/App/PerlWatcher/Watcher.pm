package App::PerlWatcher::Watcher;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/string_to_level :levels/;
use Carp;
use Devel::Comments;
use Clone qw(clone);
use Hash::Merge qw( merge );
use List::Util qw( max );

sub active {
    my ( $self, $value ) = @_;
    if ( defined($value) ) {
        delete $self->{_w} unless $value;
        $self->start if $value;
    }
    return defined( $self->{_w} );
}

sub description {
     croak 'Method "description" not implemented by subclass';
}

sub initial_status {
    my $self = shift;
    return  App::PerlWatcher::Status->new(
        watcher     => $self,
        level       => LEVEL_ANY,
        description => sub {  $self->description; },
    );
}

#
# protected methods
#

sub _key_for_value {
    my ($target, %h) = @_;
    my %reversed = reverse %h;
    return $reversed{ $target } ;
}

sub _install_thresholds {
    my ( $self, $engine_config, $config ) = @_;
    my ( $r, $l ) = (
        clone( $engine_config -> {defaults} -> {behaviour} ),
        clone( $config        -> {on} // {} ),
    );
    my $threshold = merge( $r, $l );
    # merging
    ## $threshold
    ## $l
    ## $r
    for my $k ('ok', 'fail') {
        while (my ($key, $value) = each %{ $threshold -> {$k} } ) {
            ## $k
            ## $key
            ## $value
            my $right = _key_for_value( $value, %{ $r->{$k} } );
            my $left  = _key_for_value( $value, %{ $l->{$k} } );
            ## $right
            ## $left
            delete $threshold -> {$k} -> {$right} 
                if ( defined($right) && defined($left) );
        }
    }
    ## $threshold
    #changing from human-readable to numeric values
    for my $k ('ok', 'fail') {
        while (my ($key, $value) = each %{ $threshold -> {$k} } ) {
            $threshold -> {$k} -> {$key} 
                = string_to_level( $value );
        }
    }
    ## $threshold
    $self -> {_threshold} = $threshold; 
}

sub _interpret_result {
    my ($self, $result, $callback, $items) = @_;
    my $thresholds = $self -> {_threshold};
    # $thresholds
    
    croak "Thresholds hasn't been installed" unless $thresholds;
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
    
    my @levels = sort keys (%{ $thresholds -> {$meta_key} });
    # @levels
    # $counter
    my $level_key = max grep { $_ <= $counter } @levels;
    # $level_key
    if ( defined $level_key ) {
        my $new_level = $thresholds -> {$meta_key} -> {$level_key};
        $self -> {_last_level} = $new_level; 
    }
    my $level = $self -> {_last_level};
    # $level
    $self -> {_last_result} = $result;
    $self->_emit_event($level, $callback, $items);
}

sub _emit_event {
    my ($self, $level, $callback, $items) = @_;
    my $status = App::PerlWatcher::Status->new(
        watcher     => $self,
        level       => $level,
        description => sub {  $self->description  },
        items       => $items,
    );
    $callback->($status);
}

1;
