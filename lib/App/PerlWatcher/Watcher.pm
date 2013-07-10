package App::PerlWatcher::Watcher;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/string_to_level :levels/;
use Carp;
#use Devel::Comments;
use Clone qw(clone);
use Hash::Merge qw( merge );
use List::Util qw( max );

use overload fallback => 1,
     '""' => 'description'; 

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

sub _install_thresholds {
    my ( $self, $engine_config, $config ) = @_;
    my ( $r, $l ) = (
        $engine_config -> {defaults} -> {behaviour},
        $config        -> {on} // {},
    );
    my $threshold;
    for my $k ('ok', 'fail') {
        my $merged = _merge($l->{$k}, $r->{$k});
        # from human strings to numbers
        while (my ($key, $value) = each %$merged ){
            $merged->{$key} = string_to_level($value);
        }
        $threshold->{$k} = $merged;
    }
    $self -> {_threshold} = $threshold;
}

sub _merge {
    my ($l, $r) = @_;
    
    my $max_re = qr/(.*)\/max/;
    my $level = sub { 
        my $a = shift;
        return ($a =~ /$max_re/) ? $1 : $a;
    };
    my $wrap = sub {
        my $hash_ref = shift;
        my %cleaned = map { $_ => ( $level->($hash_ref->{$_}) ) }
            keys %$hash_ref;
        ### %cleaned
        my %level_for = reverse %cleaned;
        my @levels = keys %level_for;
        ### @levels;
        my @prepared_result =  
            sort { $a->{weight} <=> $b->{weight} }
            map { 
                    my $value = $level_for{$_};
                    my $max = $hash_ref->{ $value } =~ /$max_re/;
                    {
                        level   => $_, 
                        value   => $value, 
                        weight  => string_to_level($_),
                        max     => $max,   
                    };
            } @levels;
        return @prepared_result;
    };
    
    # prepare/wrap left part
    my @l_result = $wrap->($l);
    ### @l_result
    my $max_weight = max 
        map { $_->{weight} } 
        grep { $_->{max} } @l_result;
    my %l_value_of = map { $_->{level} => $_ } @l_result;
    
    # join with right part (if there was no key in left) 
    my @r_result =
        grep { $max_weight ? ($_->{weight} <= $max_weight) : 1 }
        grep { !exists $l_value_of{ $_->{level} }  }
        $wrap->($r);
    push @l_result, $_ for ( @r_result );
    ### @l_result
    
    # unwrap
    return { map { $_->{value} => $_->{level} } @l_result };
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
