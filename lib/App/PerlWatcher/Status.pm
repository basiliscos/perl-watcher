package App::PerlWatcher::Status;
# ABSTRACT: Represents the result of single watcher poll

use 5.12.0;
use strict;
use warnings;

use Carp;
use Function::Parameters qw(:strict);
use Smart::Comments -ENV;
use Moo;

use App::PerlWatcher::Level;

=attr watcher

The watcher, to which current status relates to

=cut

has 'watcher'       => ( is => 'rw');

=attr level

The level of severity of single watcher poll (notice..alert)

=cut

has 'level'         => ( is => 'rw');

=attr description

Closure, which beign invoked, returns string, describing current
status.

=cut

has 'description'   => ( is => 'rw');

=attr items

Closure, which beign invoked, returns array ref of EventItems.

=cut 

has 'items'         => ( is => 'rw');

=attr timestamp

The timestamp of status. The default value is just a current time.

=cut

has 'timestamp'     => ( is => 'rw', default => sub { time(); });

=func updated_from

Checks weather the current status $a differs from the other status $b.
The both statuses considered the same if they have the same level and
the same items. Items are compared by content. All timestamps have no
affect on the result.

=cut

fun updated_from($a, $b) {
    carp unless $a->watcher->unique_id eq $b->watcher->unique_id;
    my $updated = ($a->level != $b->level)
        || (defined($a->items) && !defined($b->items))
        || (!defined($a->items) && defined($b->items))
        || (defined($a->items) && defined($b->items) 
                && _items_change_detector($a->items->(), $b->items->()) 
            );
    # $updated
    return $updated;
}

fun _equals_items($a, $b) {
    # $a
    # $b
    my $result = !($a->content cmp $b->content); #|| ($a->timestamp <=> $b->timestamp) );
    # $result
    return $result; 
}

fun _items_change_detector($a, $b) {
    # $a
    # $b
    return 1 if(@$a != @$b);
    for my $i (0..@$a-1) {
        return 1 
            if ! _equals_items(
                @{ $a }[$i],
                @{ $b }[$i],
            );
    }
    return 0;
}

sub STORABLE_freeze {
    my ($self, $cloning) = @_;
    my $values_hash_ref = {};
    my @copy_props = qw/watcher level timestamp/;
    @$values_hash_ref{ @copy_props } = map { $self->$_() } @copy_props;
    $values_hash_ref->{_description_value} = $self->description->();
    my $items = $self->items;
    $values_hash_ref->{_items_value} = $items ? $items->() : undef;
    return ("", $values_hash_ref); 
}

sub STORABLE_thaw {
    my ($self, $cloning, $serialized, $values_hash_ref) = @_;
    my @copy_props = qw/watcher level timestamp/;
    for my $p (@copy_props) {
        $self->$p($values_hash_ref->{$p});
    }
    $self->description( sub { $values_hash_ref->{_description_value} } );
    $self->items( sub { $values_hash_ref->{_items_value} } )
        if $values_hash_ref->{_items_value};
}

1;
