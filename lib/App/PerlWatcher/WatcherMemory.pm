package App::PerlWatcher::WatcherMemory;
{
  $App::PerlWatcher::WatcherMemory::VERSION = '0.16_3';
}
# ABSTRACT: Represents watcher memory, which can be persisted (detached) from Watcher

use 5.12.0;
use strict;
use warnings;

use Carp;
use List::Util qw( max );
use Moo;

use App::PerlWatcher::Levels;


has 'thresholds_map'    => ( is => 'ro', required => 1);


has 'last_level'        => ( is => 'rw', default => sub { LEVEL_NOTICE; } );


has 'active' => (is => 'rw', default => sub { 1 } );


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

__END__

=pod

=head1 NAME

App::PerlWatcher::WatcherMemory - Represents watcher memory, which can be persisted (detached) from Watcher

=head1 VERSION

version 0.16_3

=head1 ATTRIBUTES

=head2 thresholds_map

The map, which represents how to interpret successul or unsuccessful result, i.e.
which level of severity it is. It looks like:

 my $map = {
    fail => { 
        3   =>  'info',
        5   =>  'alert',
    },
    ok  => { 3 => 'notice' },
 };

=head2 last_level

Represents last emitted watcher level. 

=head2 active

Represents whether the watcher is active or not

=head1 METHODS

=head2 interpret_result

Does result interpretation in accordanse with thresholds_map. The result is boolean: true
or false (or coerced to them). Returns the resulting level of interpretation.

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
