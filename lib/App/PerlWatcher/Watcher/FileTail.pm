package App::PerlWatcher::Watcher::FileTail;

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Handle;
use App::PerlWatcher::EventItem;
use App::PerlWatcher::Status qw/:levels/;
use App::PerlWatcher::Watcher;
use Carp;
use Devel::Comments;
use File::ReadBackwards;
use Linux::Inotify2;

use base qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    
    my ( $file, $line_number ) = @config{ qw/ file lines / };
    
    $line_number //= 10;
    croak("file is undefined") unless defined ($file);

    my $inotify = Linux::Inotify2->new
      or croak("unable to create new inotify object: $!");

    my $self = {
        _inotify     => $inotify,
        _line_number => $line_number,
        _file        => $file,
        _events      => [],
    };

    return bless $self, $class;
}

sub start {
    # starting watch file
    my $self = shift;
    $self->{_callback} //= shift;

    my $file_handle = $self->_initial_read;

    $self->{_inotify}->watch(
        $self->{_file},
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
        fh   => $self->{_inotify}->fileno,
        poll => 'r',
        cb   => sub {
            $self->{_inotify}->poll
              if defined( $self->{_w} );
        },
    );
}

sub description {
    my $self = shift;
    return "FileWatcher [" . $self->{_file} . "]";
}

sub _add_line {
    my ( $self, $line ) = @_;
    if ( defined $line ) {
        chomp $line;
        my $event_item = App::PerlWatcher::EventItem->new($line);
        $event_item -> timestamp(0);
        # $line
        my $evens_queue = $self->{_events};
        push @$evens_queue, $event_item;
        shift @$evens_queue if @$evens_queue > $self->{_line_number};
        $self->_trigger_callback;
    }
}

sub _trigger_callback {
    my ($self) = @_;
    my @events = @{ $self->{_events} };
    my $status = App::PerlWatcher::Status->new(
        watcher     => $self,
        level       => LEVEL_NOTICE,
        description => sub { $self->description },
        items       => sub { \@events },
    );
    $self->{_callback}->($status);
}

sub _initial_read {
    my ($self)       = @_;
    my $frb          = File::ReadBackwards->new( $self->{_file} );
    my $end_position = $frb->tell;
    my @last_lines;
    unshift @last_lines, $frb->readline for 1 .. $self->{_line_number};
    $self->_add_line($_) for (@last_lines);

    my $file_handle = $frb->get_handle;

    # move file pointer to the end
    seek $file_handle, 0, 2;
    return $file_handle;
}

1;
