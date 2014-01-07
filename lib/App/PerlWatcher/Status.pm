package App::PerlWatcher::Status;
{
  $App::PerlWatcher::Status::VERSION = '0.20';
}
# ABSTRACT: Represents the result of single watcher poll

use 5.12.0;
use strict;
use warnings;

use Carp;
use Function::Parameters qw(:strict);
use Smart::Comments -ENV;
use Moo;
use Types::Standard qw/Maybe CodeRef Num/;

use aliased qw/Type::Tiny::Role/;
use aliased qw/App::PerlWatcher::Level/;
use aliased qw/App::PerlWatcher::Watcher/;

use App::PerlWatcher::Level;


has 'watcher' => ( is => 'rw', isa => Role->new(role => Watcher));


has 'level' => ( is => 'rw', isa => Role->new(role => Level));


has 'description' => ( is => 'rw', isa => CodeRef);


has 'items' => ( is => 'rw', isa => Maybe[CodeRef]);


has 'timestamp' => (
    is => 'rw',
    default => sub { time(); },
    isa => Num,
);


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

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Status - Represents the result of single watcher poll

=head1 VERSION

version 0.20

=head1 ATTRIBUTES

=head2 watcher

The watcher, to which current status relates to

=head2 level

The level of severity of single watcher poll (notice..alert)

=head2 description

Closure, which beign invoked, returns string, describing current
status.

=head2 items

Closure, which beign invoked, returns array ref of EventItems.

=head2 timestamp

The timestamp of status. The default value is just a current time.

=head1 FUNCTIONS

=head2 updated_from

Checks weather the current status $a differs from the other status $b.
The both statuses considered the same if they have the same level and
the same items. Items are compared by content. All timestamps have no
affect on the result.

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
