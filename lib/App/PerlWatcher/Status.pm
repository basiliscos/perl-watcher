package App::PerlWatcher::Status;
{
  $App::PerlWatcher::Status::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::Comments;
use Moo;

use App::PerlWatcher::Level;

has 'watcher'       => ( is => 'rw');
has 'level'         => ( is => 'rw');
has 'description'   => ( is => 'rw');
has 'items'         => ( is => 'rw');
has 'timestamp'     => ( is => 'rw', default => sub { time(); });

sub updated_from {
    my ($a, $b) = @_;
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

sub _equals_items {
    my ($a, $b) = @_;
    # $a
    # $b
    my $result = !( ($a->content cmp $b->content) || ($a->timestamp <=> $b->timestamp) );
    # $result
    return $result; 
}

sub _items_change_detector {
    my ($a, $b) = @_;
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
