package App::PerlWatcher::Engine;
{
  $App::PerlWatcher::Engine::VERSION = '0.13';
}
# ABSTRACT: Creates Watchers and lets them  notify Frontend with their's Statuses

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Class::Load ':all';
use Data::Dumper;
use Devel::Comments;
use File::Spec;
use Moo;
use Path::Class qw(file);

use App::PerlWatcher::Shelf;
use App::PerlWatcher::Util::Bootstrap qw/get_home_dir/;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;


has 'frontend'          => ( is => 'rw');


has 'config'            => ( is => 'ro', required => 0);

has 'backend'           => ( is => 'ro', required => 1);


has 'statuses_file'     => ( is => 'ro', default => sub {
        return file(File::Spec->catfile(get_home_dir(), "statuses-shelf.data"));
    });


has 'watchers'          => ( is => 'lazy');


has 'watchers_order'    => ( is => 'lazy');


has 'shelf'             => ( is => 'rw');

sub _build_watchers {
    my $self = shift;
    my $config = $self->config;
    my @r;
    for my $watcher_definition ( @{ $config -> {watchers} } ) {
        my ($class, $watcher_config )
            = @{ $watcher_definition }{ qw/class config/ };
        my $watcher;
        eval {
            load_class($class);
            $watcher = $class->new( engine_config => $config, %$watcher_config );
            push @r, $watcher;
        };
        carp "Error creating watcher $class : $@" if $@;
    }
    return \@r;
}

sub _build_watchers_order {
    my $self = shift;
    my $watchers = $self->watchers;
    my $order = {};
    $order->{ $watchers->[$_] } = $_ for 0 .. @$watchers - 1;
    return $order;
}

sub _build_shelf {
    my $self = shift;
    my $statuses_file = $self->statuses_file;
    if ( -r $statuses_file ) {
        my $data = $statuses_file->slurp;
        thaw($self, $data)
            and return $self->shelf;
    }
    return App::PerlWatcher::Shelf->new;
}

sub BUILD {
    my $self = shift;
    $self->shelf($self->_build_shelf);
}


sub start {
    my $self = shift;
    for my $w ( @{ $self->watchers } ) {
        $w->start(
            sub {
                my $status = shift;
                AnyEvent::postpone {
                    $self->frontend->update($status);
                };
            }
        );
    }
    # actually trigger watchers
    $self->backend->start_loop;
}


sub stop {
    my $self = shift;
    $self->backend->stop_loop;

    my $data = freeze($self);
    $self->statuses_file->spew($data);
}


sub sort_statuses {
    my ($self, $statuses) = @_;
    my $order_of = $self->watchers_order;
    return [
        sort {
            $order_of->{ $a->watcher } <=> $order_of->{ $b->watcher };
        } @$statuses
    ];
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Engine - Creates Watchers and lets them  notify Frontend with their's Statuses

=head1 VERSION

version 0.13

=head1 SYNOPSIS

 # define own frontend in separate package

 package My::FrontEnd;

 use Moo;
 with 'App::PerlWatcher::Frontend';

 sub update {
    my ( $self, $status ) = @_;
    say $status->level;
 }


 # define engine config with reqired watchers

 $config = {
    watchers => [
        {
            class => 'App::PerlWatcher::Watcher::Ping',
            config => {
                host    =>  'google.com',
                port    =>  80,
                frequency   =>  10,
                timeout     => 1,
                on => {
		  fail => {
                      3   =>  'info',
		      5   =>  'warn',
		      8   =>  'alert',
		    }
                   ok   => { 1 => 'notice'},
                },
            },
        },
    ],
 };

 # initialization: bring all pieces together
 my $frontend = My::FrontEnd->new(engine => $engine);
 my $backend  = My::BackEnd->new;

 $engine = Engine->new(config => $config, backend => $backend)
 $engine->frontend( $app );

 $engine->start;
 # now if google is down, it says ping status with interpetation
 # notice
 # notice
 # notice
 # info
 # info
 # warn
 # ...

=head1 ATTRIBUTES

=head2 config

Required config, which defines watchers behaviour. See engine.conf.example

=head2 backend

AnyEvent supported backed (loop engine), generally defined by using frontend,
i.e. for Gtk2-frontend it should call Gtk2->main

=head2 statuses_file

Defines, where the Engine state is to be serialized. Default value:
$HOME/.perl-watcher/statuses-shelf.data

=head2 watchers

An array_ref of Watcher instances. Watchers order is the same as it was
defined in config

=head2 watchers_order

Return an map "watcher to watcher order".

=head2 shelf

Defines statuses shelf, where remembered watcher statuses are stored. It is
needed because, where could be statuses, to which user does not payed attention,
and they should not be stored.

=head1 METHODS

=head2 start

Starts all watchers and backend.

=head2 stop

Stops backend, all watchers and persists current state (watchers memories
and shelf)

=head2 sort_statuses

Helper method which sorts statuses in accordance with theirs watchers
order

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
