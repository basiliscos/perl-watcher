package App::PerlWatcher::Watcher;
{
  $App::PerlWatcher::Watcher::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Level qw/get_by_description :levels/;
use App::PerlWatcher::Status;
use aliased 'App::PerlWatcher::WatcherMemory';
use Carp;
use Devel::Comments;
use Digest::MD5 qw(md5_base64);
use List::Util qw( max );
use Storable qw/freeze/;


use Moo::Role;

requires 'description';
has 'engine_config'     => ( is => 'ro', required => 1);
has 'init_args'         => ( is => 'rw');
has 'config'            => ( is => 'lazy');
has 'unique_id'         => ( is => 'lazy');
has 'memory'            => ( is => 'rw');
has 'callback'          => ( is => 'rw');

use overload fallback => 1, q/""/ => sub { $_[0]->unique_id; };


sub BUILD {
    my ($self, $init_args) = @_;
    $self->init_args($init_args);
    $self->memory($self->_build_memory);
}

sub _build_config {
    my $self = shift;
    my @clean_init_keys = 
        grep {$_ ne 'engine_config'} 
        keys %{ $self->init_args };
    my %config;
    @config{ @clean_init_keys} = @{ $self->init_args }{ @clean_init_keys };
    return \%config;
}

sub _build_memory {
    my $self = shift;
    my ( $l, $r ) = (
        $self->config        -> {on} // {},
        $self->engine_config -> {defaults}->{behaviour},
    );
    my $map = calculate_threshods($l, $r);
    return WatcherMemory->new(thresholds_map=>$map);
}

sub _build_unique_id {
    my $self = shift;
    my $class = ref($self);
    my $config = $self->config;
    my @clean_keys = grep { (ref($config->{$_}) // '?') ne 'CODE' }
        keys %$config;
    my @values = sort @{ $config }{ @clean_keys };
    my $hash = md5_base64(freeze(\@values));
    my $id = "$class/$hash";
    ## @values
    ## $id
}

sub active {
    my ( $self, $value ) = @_;
    if ( defined($value) ) {
        delete $self->{_w} unless $value;
        $self->start if $value;
    }
    return defined( $self->{_w} );
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
    
    my $level = $self->memory->interpret_result($result);
    
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

# storable-methods
sub STORABLE_freeze {
    "$_[0]";
};

sub STORABLE_attach {
    my ($class, $cloning, $serialized) = @_;
    my $id = $serialized;
    my $w = $App::PerlWatcher::Util::Storable::Watchers_Pool{$id};
    
    # we are forced to return dummy App::PerlWatcher::Watcher
    # it will be filtered later
    unless($w){
       $w = { _unique_id => 'dummy-id'};
       bless $w => $class;
    }
    return $w;
}

1;
