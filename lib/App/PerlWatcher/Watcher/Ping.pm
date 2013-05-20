package App::PerlWatcher::Watcher::Ping;

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Socket;
use App::PerlWatcher::Status qw/:levels :results/;
use App::PerlWatcher::Watcher;
use Carp;
use Devel::Comments;

our @ISA = qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    my ( $host, $port, $frequency, $timeout ) 
        = @config{ qw/ host port frequency timeout / };
        
    croak("host is not defined") unless defined ($host);
    croak("port is not defined") unless defined ($port);
    
    $frequency  //= 60;
    $timeout    //= $engine_config -> {timeout} // 5;

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
                    $success  ? RESULT_OK : RESULT_FAIL,
                    LEVEL_NOTICE,
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
