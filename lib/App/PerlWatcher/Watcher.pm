package App::PerlWatcher::Watcher;
{
  $App::PerlWatcher::Watcher::VERSION = '0.10';
}

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Level qw/get_by_description :levels/;
use App::PerlWatcher::Status;
use App::PerlWatcher::WatcherMemory;
use Carp;
use Devel::Comments;
use Digest::MD5 qw(md5_base64);
use List::Util qw( max );
use Storable qw/freeze/;

use overload fallback => 1,
     '""' => 'unique_id'; 

sub new {
    my ($class, $engine_config, %config) = @_;
    my @clean_keys = grep { (ref($config{$_}) // '?') ne 'CODE' } 
        keys %config;
    my @values = sort @config{ @clean_keys };
    my $hash = md5_base64(freeze(\@values));
    my $id = "$class/$hash";
    ## @values
    ## $id
    my $self = {_unique_id => $id};
    bless $self => $class;
    return $self;
}

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

sub unique_id {
    return shift->{_unique_id};
}

sub memory {
    my ($self, $value) = @_;
    $self -> {_memory} = $value if defined($value);
    return $self -> {_memory};
}

sub calculate_threshods {
    my ($l, $r) = @_;
    my $thresholds_map;
    for my $k ('ok', 'fail') {
        my $merged = _merge($l->{$k}, $r->{$k});
        # from human strings to numbers
        while (my ($key, $value) = each %$merged ){
            $merged->{$key} = get_by_description($value);
        }
        $thresholds_map->{$k} = $merged;
    }
    return $thresholds_map;
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
    my $map = calculate_threshods($l, $r);
    my $memory = App::PerlWatcher::WatcherMemory->new($map);
    $self->memory($memory);
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
        ## %cleaned
        my %level_for = reverse %cleaned;
        my @levels = keys %level_for;
        ## @levels;
        my @prepared_result =  
            sort { $a->{weight} <=> $b->{weight} }
            map { 
                    my $value = $level_for{$_};
                    my $max = $hash_ref->{ $value } =~ /$max_re/;
                    {
                        level   => $_, 
                        value   => $value, 
                        weight  => get_by_description($_)->value,
                        max     => $max,   
                    };
            } @levels;
        return @prepared_result;
    };
    
    # prepare/wrap left part
    my @l_result = $wrap->($l);
    ## @l_result
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
    ## @l_result
    
    # unwrap
    return { map { $_->{value} => $_->{level} } @l_result };
}

sub _interpret_result {
    my ($self, $result, $callback, $items) = @_;
    
    my $level = $self->{_memory}->interpret_result($result);
    
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
