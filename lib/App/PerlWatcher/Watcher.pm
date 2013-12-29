package App::PerlWatcher::Watcher;
{
  $App::PerlWatcher::Watcher::VERSION = '0.20';
}
# ABSTRACT: Observes some external source of events and emits the result of polling them

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Levels;
use App::PerlWatcher::Memory qw /memory_patch/;
use App::PerlWatcher::Status;

use Carp;
use Data::Dump::Filtered qw/dump_filtered/;
use Smart::Comments -ENV;
use Digest::MD5 qw(md5_base64);
use List::Util qw( max );
use Storable qw/freeze/;

use Moo::Role;

with qw/App::PerlWatcher::Describable/;
with qw/App::PerlWatcher::Memorizable/;


has 'engine_config'     => ( is => 'ro', required => 1);


has 'init_args'         => ( is => 'rw');


has 'config'            => ( is => 'lazy');


has 'unique_id'         => ( is => 'lazy');


memory_patch(__PACKAGE__, 'active');


memory_patch(__PACKAGE__, 'thresholds_map');


memory_patch(__PACKAGE__, 'last_status');


has 'poll_callback' => (is => 'rw', default => sub { sub{};  } );


has 'callback'          => ( is => 'rw', required => 1);


has 'watcher_guard'     => ( is => 'rw');


requires 'build_watcher_guard';

use overload fallback => 1, q/""/ => sub { $_[0]->unique_id; };

sub BUILD {
    my ($self, $init_args) = @_;
    $self->init_args($init_args);
    $self->_init_thresholds_map;
    $self->active(1);
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

sub _init_thresholds_map {
    my $self = shift;
    my ( $l, $r ) = (
        $self->config        -> {on} // {},
        $self->engine_config -> {defaults}->{behaviour},
    );
    my $map = calculate_threshods($l, $r);
    $self->thresholds_map($map);
}

sub _build_unique_id {
    my $self = shift;
    my $class = ref($self);
    # Filter strips down the subroutine references
    # and transforms hashes to arrays sorted by keys.
    # this is needed to always have the same string
    # for the same config, any change will lead
    # to change of md5, and the id will be different.
    my $filter; $filter = sub {
        my($ctx, $object_ref) = @_;
        my $ref_type = ref($object_ref);
        return { object => 'FILTERED' } if ($ref_type eq 'CODE');
        return undef                    if ($ref_type ne 'HASH');
        my @determined_array =
            map {
                my $stringized_value = dump_filtered($object_ref->{$_}, $filter);
                my $value = eval $stringized_value;
                ($_ => $value);
            } sort keys %$object_ref;
        return { dump => dump_filtered(\@determined_array, $filter) };
    };
    my $dumped_config = dump_filtered($self->config, $filter);
    my $hash = md5_base64($dumped_config);
    my $id = "$class/$hash";
}


sub force_poll {
    my $self = shift;
    $self->activate(0);
    $self->activate(1);
}


sub activate {
    my ( $self, $value ) = @_;
    if ( defined($value) ) {
        $self->active($value);
        $self->watcher_guard(undef)
            unless $value;
        $self->start if $value;
    }
    return $self->active;
}


sub start {
    my $self = shift;
    $self->watcher_guard( $self->build_watcher_guard )
        if $self->active;
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


sub interpret_result {
    my ($self, $result, $callback, $items) = @_;

    my $prev_status = $self->last_status;
    my $prev_level = $prev_status && $prev_status->level;
    my $level = $self->_interpret_result_as_level($result, $prev_level);
    $self->_emit_event($level, $callback, $items);
}

sub _interpret_result_as_level {
    my ($self, $result, $last_level) = @_;
    $last_level //= LEVEL_NOTICE;
    my $threshold_map = $self->thresholds_map;

    $self->memory->data->{_last_result} //= $result;
    my ($meta_key, $opposite_key)
        = $result ? ('ok',   'fail')
                  : ('fail',  'ok' );

    my $counter_key          =  "_$meta_key" . "_counter";
    my $opposite_counter_key =  "_$opposite_key" . "_counter";

    my $result_changed = $self->memory->data->{_last_result} ne $result;
    # reset values
    if ($result_changed) {
        $self->memory->data->{$counter_key}
            = $self->memory->data->{$opposite_counter_key}
            = 0;
    }
    my $counter = ++$self->memory->data->{$counter_key};

    my @levels = sort keys (%{ $threshold_map -> {$meta_key} });
    # @levels
    # $counter
    my $level_key = max grep { $_ <= $counter } @levels;
    # $level_key

    my $result_level = ( defined $level_key )
        ? $threshold_map->{$meta_key}->{$level_key}
        : $last_level;
    $self->memory->data->{_last_result} = $result;

    return $result_level;
}

sub _emit_event {
    my ($self, $level, $callback, $items) = @_;
    my $prev_status = $self->last_status;
    my $prev_items = $prev_status ? $prev_status->items : undef;
    _merge_items($prev_items, $items);
    my $status = App::PerlWatcher::Status->new(
        watcher     => $self,
        level       => $level,
        description => sub { $self->describe },
        items       => $items,
    );
    # remember it
    $self->last_status($status);
    $callback->($status);
}

# move the matching by content EventItems from old to new 
sub _merge_items {
    my ($old_items_fun, $new_items_fun) = @_;
    return if(!$old_items_fun || !$new_items_fun);

    my ($old_items, $new_items) = map { $_->() } @_;

    my %copied;
    for my $i (0 .. @$new_items-1) {
        for my $j (0 .. @$old_items-1) {
            if ($new_items->[$i]->content eq $old_items->[$j]->content
                && !$copied{$j}) {
                $new_items->[$i] = $old_items->[$j];
                $copied{$j} = 1;
                last;
            }
        }
    }
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

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Watcher - Observes some external source of events and emits the result of polling them

=head1 VERSION

version 0.20

=head1 ATTRIBUTES

=head2 engine_config

Holds an reference to engine config (used in construction watcher's thresholds_map)

=head2 init_args

Remembers the arguments for watcher construction (used in construction watcher's
thresholds_map and unique_id)

=head2 config

The wacher configuration hash ref.

=head2 unique_id

Represents watchers unique_id, calculated from concrete watcher class and
watcher's config. The unique_id is overloaded "to-string" operation, so
watcher can be used to as hash key. unique_id is also used when the
PerlWatcher state is been persisted : the watcher itself isn't stored, but
it's unique_id is stored. That guarantees that unique_id is the same between
PerlWatcher invokations (that's why the perl internal hash funciton isn't used)

=head2 active

Memorizable attribute, defines, weather the current watcher is active

=head2 thresholds_map

The memorizable map, which represents how to interpret successul or
unsuccessful result, i.e. which level of severity it is. It looks like:

 my $map = {
    fail => {
        3   =>  'info',
        5   =>  'alert',
    },
    ok  => { 3 => 'notice' },
 };

=head2 last_status

Represents last emitted watcher status

=head2 poll_callback

The subroutine reference, which is been called before every poll of watcher external source.

 $watcher->poll_callback($watcher);

=head2 callback

The subroutine reference, which is been called after every poll of watcher external source.
It's argument is the State, i.e.

 $watcher->callback($state)

=head2 watcher_guard

The watcher guard returned by AnyEvent->io, AnyEvent->timer etc, with is an core
under wich the Watcher is been build.

=head1 METHODS

=head2 build_watcher_guard

The method is responsible for building watcher_guard

=head2 force_poll

Immediatly polls the watched object.

=head2 activate

Turns on and off the wacher, remembering the state in memory

=head2 start

Starts the watcher, which will emit it's statuses. The watcher will
start only it is active.

=head2 calculate_threshods

Calculates the thresholds_map based on the left map and righ map
The left map has precedence. Usualy the left map is the watchers
config, while the righ map is the generic PerlWatcher/Engine config

=head2 interpret_result

This method interprets the result of poll (true or false)
in accordance with thresholds_map and the callback will
be called with the resulting status (and optionally provided
items). Meant to be called from subclases, e.g.

 $watcher->interpret_result(0, $callback);

The items can be tacken from the previous result interpreation
if they match by content

$items is an coderef, which actually returns array of items.

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
