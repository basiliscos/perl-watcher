package App::PerlWatcher::Watcher::Ping;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status;
use App::PerlWatcher::Watcher;
use Devel::Comments;
use AnyEvent::Socket;

our @ISA = qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $host, $port, $frequency, $timeout ) = @_;

    my $self;
    $self = {
        _watcher => sub {
            my $callback = shift;
            tcp_connect $host, $port, sub {
                my $success = @_;

                # $! contains error
                ### $host
                ### $success
                my $status = App::PerlWatcher::Status->new(
                    $self,
                    $success
                    ? $App::PerlWatcher::Status::RESULT_OK
                    : $App::PerlWatcher::Status::RESULT_FAIL,
                    $App::PerlWatcher::Status::LEVEL_NOTICE,
                    sub { $self->description },
                );
                $callback->($status);
              }, sub {

                #connect timeout
                #my ($fh) = @_;

                1;
              };
        },
        _frequency => $frequency,
        _host      => $host,
        _port      => $port,
    };
    return bless $self, $class;
}

sub start {
    my $self = shift;
    $self->{_callback} //= shift;
    $self->{_w} = AnyEvent->timer(
        after    => 0,
        interval => $self->{_frequency},
        cb       => sub {
            $self->{_watcher}->( $self->{_callback} )
              if defined( $self->{_w} );
        }
    );
}

sub description {
    my $self = shift;
    return "Ping " . $self->{_host} . ":" . $self->{_port};
}

1;
