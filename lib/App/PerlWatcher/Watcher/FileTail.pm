package App::PerlWatcher::Watcher::FileTail;
{
  $App::PerlWatcher::Watcher::FileTail::VERSION = '0.13';
}
# ABSTRACT: Watches for changes file and outputs new added lines (a-la 'tail -f')

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Handle;
use App::PerlWatcher::EventItem;
use App::PerlWatcher::Levels;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher;
use Carp;
use Devel::Comments;
use File::ReadBackwards;
use Linux::Inotify2;
use Moo;


has 'file'          => ( is => 'ro', required => 1);


has 'lines_number'  => ( is => 'ro', required => 1);


has 'filter'        => ( is => 'ro', default => sub { return sub {1; } } );


has 'inotify'       => ( is => 'lazy' );


has 'events'        => ( is => 'lazy', default => sub { [] } );

with qw/App::PerlWatcher::Watcher/;

sub _build_inotify {
    my $inotify = Linux::Inotify2->new
        or croak("unable to create new inotify object: $!");
    return $inotify;
}

sub start {
    # starting watch file
    my ($self, $callback) = @_;
    $self->callback($callback) if $callback;

    my $file_handle = $self->_initial_read;

    $self->inotify->watch(
        $self->file,
        IN_MODIFY,
        sub {
            my $e    = shift;
            my $name = $e->fullname;
            # cancel this watcher: remove no further events
            #$e->w->cancel;
            my $ae_handle;
            $ae_handle = AnyEvent::Handle->new(
                fh      => $file_handle,
                on_read => sub {
                    my ($ea_handle) = @_;
                    $ea_handle->push_read(
                        line => sub {
                            my ( $ea_handle, $line, $eof ) = @_;
                            #print $line, $eof;
                            $self->_add_line($line);
                        }
                    );
                },
                on_eof => sub {
                    # eof
                    undef $ae_handle;
                },
            );
        }
    );

    $self->{_w} = AnyEvent->io(
        fh   => $self->inotify->fileno,
        poll => 'r',
        cb   => sub {
            $self->inotify->poll
              if defined( $self->{_w} );
        },
    );
}

sub description {
    my $self = shift;
    return "FileWatcher [" . $self->file . "]";
}

sub _add_line {
    my ( $self, $line ) = @_;
    if ( defined $line ) {
        chomp $line;
        if ( $self->filter->(local $_ = $line) ) {
            my $event_item = App::PerlWatcher::EventItem->new(
                content     => $line,
                timestamp   => 0,
            );
            # $line
            my $evens_queue = $self->events;
            push @$evens_queue, $event_item;
            shift @$evens_queue if @$evens_queue > $self->lines_number;
            $self->_trigger_callback;
        }
    }
}

sub _trigger_callback {
    my ($self) = @_;
    my @events = @{ $self->events };
    my $status = App::PerlWatcher::Status->new(
        watcher     => $self,
        level       => LEVEL_NOTICE,
        description => sub { $self->description },
        items       => sub { \@events },
    );
    $self->callback->($status);
}

sub _initial_read {
    my ($self)       = @_;
    my $frb          = File::ReadBackwards->new( $self->file );
    my $end_position = $frb->tell;
    my @last_lines;
    my $line;
    do {
        $line = $frb->readline;
        unshift @last_lines, $line
            if ( $line  && $self->filter->(local $_ = $line) );
    } while (defined($line) && @last_lines < $self->lines_number );

    $self->_add_line($_) for (@last_lines);

    my $file_handle = $frb->get_handle;

    # move file pointer to the end
    seek $file_handle, 0, 2;
    return $file_handle;
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Watcher::FileTail - Watches for changes file and outputs new added lines (a-la 'tail -f')

=head1 VERSION

version 0.13

=head1 ATTRIBUTES

=head2 file

The file to be watched.

=head2 lines_number

The number of at the file tail, which are to be displayed

=head2 filter

The function, which will filter file tail lines, which will not
be displayed/taken into account, e.g.

 sub { $_ !~ /\scron/ }

- that omits all lines with 'cron' string

=head2 inotify

The inotify object

=head2 events

All gathered lines

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
