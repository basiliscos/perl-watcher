package App::PerlWatcher::Engine;
# ABSTRACT: Creates Watchers and lets them  notify Frontend with their's Statuses

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use Carp;
use Class::Load ':all';
use Smart::Comments -ENV;
use File::Spec;
use Function::Parameters qw(:strict);
use List::MoreUtils qw/first_index/;
use Moo;
use Path::Tiny;

use App::PerlWatcher::Shelf;
use App::PerlWatcher::Util::Bootstrap qw/get_home_dir/;
use App::PerlWatcher::Util::Storable qw/freeze thaw/;

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
        {
            class => 'App::PerlWatcher::Watcher::GenericExecutor',
            config => {
                command       => "/bin/ls",
                arguments     => ["-1a", "/tmp/"],
                frequency     => 60,
                timeout       => 5,
                # filtering "." and ".." files
                filter        => sub { ($_ !~ /^\.{1,2}$/) && (/\S+/) },
                rules         => [
            	    warn  => sub { any { /strange_file.txt/ } @_ },
                ],
            }
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
 # or you'll get warn if strange_file.txt suddendly appears
 # in /tmp

=cut

=head1 GTK2 FRONTEND SCREENSHOT

=begin HTML

<p>
<img src="https://raw.github.com/basiliscos/images/master/PerlWatcher-0.16.png" alt="PerlWatcher GTK2 screenshot" title="PerlWatcher GTK2 screenshot" style="max-width:100%;">
</p>

=end HTML

=cut

=head1 DESCRIPTION

The more detailed description of PerlWatcher application can be found here:
L<https://github.com/basiliscos/perl-watcher>.

=cut


has 'frontend'          => ( is => 'rw');

=attr config

Required config, which defines watchers behaviour. See engine.conf.example

=cut

has 'config'            => ( is => 'ro', required => 0);

=attr backend

AnyEvent supported backed (loop engine), generally defined by using frontend,
i.e. for Gtk2-frontend it should call Gtk2->main

=cut
has 'backend'           => ( is => 'ro', required => 1);

=attr statuses_file

Defines, where the Engine state is to be serialized. Default value:
$HOME/.perl-watcher/statuses-shelf.data

=cut

has 'statuses_file'     => ( is => 'ro', default => sub {
        return path(File::Spec->catfile(get_home_dir(), "statuses-shelf.data"));
    });

=attr watchers

An array_ref of Watcher instances. Watchers order is the same as it was
defined in config

=cut

has 'watchers'          => ( is => 'lazy');

=attr polling_watchers

An array_ref of Watcher instances, which currently do poll of external resource

=cut

has 'polling_watchers' => ( is => 'ro', default => sub{ [] });

=attr watchers_order

Return an map "watcher to watcher order".

=cut

has 'watchers_order'    => ( is => 'lazy');

=attr shelf

Defines statuses shelf, where remembered watcher statuses are stored. It is
needed because, where could be statuses, to which user does not payed attention,
and they should not be stored.

=cut

has 'shelf'             => ( is => 'rw');

method _build_watchers {
    my $config = $self->config;
    my @r;
    my $poll_callback = sub {
        my $w = shift;
        push @{ $self->polling_watchers }, $w;
        $self->frontend->poll($w);
    };
    my $engine_callback = sub {
        my $status = shift;
        my $w_idx = first_index { $_->unique_id eq $status->watcher->unique_id }
            @{ $self->polling_watchers };
        splice( @{ $self->polling_watchers }, $w_idx, 1);
        AnyEvent::postpone {
            $self->frontend->update($status);
        };
    };
    for my $watcher_definition ( @{ $config -> {watchers} } ) {
        my ($class, $watcher_config )
            = @{ $watcher_definition }{ qw/class config/ };
        my $watcher;
        eval {
            load_class($class);
            $watcher = $class->new(
                engine_config => $config,
                callback      => $engine_callback,
                poll_callback => $poll_callback,
                %$watcher_config
            );
            $watcher->callback($engine_callback);
            push @r, $watcher;
        };
        carp "Error creating watcher $class : $@" if $@;
    }
    return \@r;
}

method _build_watchers_order {
    my $watchers = $self->watchers;
    my $order = {};
    $order->{ $watchers->[$_] } = $_ for 0 .. @$watchers - 1;
    return $order;
}

method _build_shelf {
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

=method start

Starts all watchers and backend.

=cut

method start {
    $_->start for ( @{ $self->watchers } );
    # actually trigger watchers
    $self->backend->start_loop;
}

=method stop

Stops backend, all watchers and persists current state (watchers memories
and shelf)

=cut

method stop {
    $self->backend->stop_loop;

    my $data = freeze($self);
    $self->statuses_file->spew($data);
}

=method sort_statuses

Helper method which sorts statuses in accordance with theirs watchers
order

=cut

method sort_statuses($statuses):($) {
    my $order_of = $self->watchers_order;
    return [
        sort {
            $order_of->{ $a->watcher } <=> $order_of->{ $b->watcher };
        } @$statuses
    ];
}

=head1 CREDITS

=over 2

Alexandr Ciornii

=back

=cut

1;
