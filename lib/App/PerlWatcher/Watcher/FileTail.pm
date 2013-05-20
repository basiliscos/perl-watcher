package App::PerlWatcher::Watcher::FileTail;

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Handle;
use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher;
use File::ReadBackwards;
use Linux::Inotify2;
use Devel::Comments;

our @ISA = qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $file, $line_number ) = @_;

    my $inotify = Linux::Inotify2->new
      or die "unable to create new inotify object: $!";

    my $self = {
        _inotify     => $inotify,
        _line_number => $line_number,
        _file        => $file,
    };

    return bless $self, $class;
}

sub start {
    ### starting watch file
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
                    ### eof
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
    return "FileWatcher[" . $self->{_file} . "]";
}

sub _add_line {
    my ( $self, $line ) = @_;
    if ( defined $line ) {
        chomp $line;
        ### $line
        push @{ $self->{_lines} }, $line;
        shift @{ $self->{_lines} }
          if @{ $self->{_lines} } > $self->{_line_number};
        $self->_trigger_callback;
    }
}

sub _trigger_callback {
    my ($self) = @_;
    my $status = App::PerlWatcher::Status->new(
        $self,
        $App::PerlWatcher::Status::RESULT_OK,
        $App::PerlWatcher::Status::LEVEL_NOTICE,
        sub { $self->description },
        sub { $self->{_lines} },
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

    #move file pointer to the end
    seek $file_handle, 0, 2;
    return $file_handle;
}

sub _get_content {
    my $self = shift;
    return join( "\n", @{ $self->{_lines} } );
}

1;
