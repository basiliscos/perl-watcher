package App::PerlWatcher::Watcher::Ping;
{
  $App::PerlWatcher::Watcher::Ping::VERSION = '0.10';
}

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Socket;
use App::PerlWatcher::Watcher;
use Carp;
use Devel::Comments;

use base qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    my ( $host, $port, $frequency, $timeout ) 
        = @config{ qw/ host port frequency timeout / };
        
    croak("host is not defined") unless defined ($host);
    croak("port is not defined") unless defined ($port);
    
    $frequency  //= 60;
    $timeout    //= $engine_config -> {defaults} -> {timeout} // 5;

    my $self = $class->SUPER::new($engine_config, %config);
    my $extendent_self = {
        _frequency => $frequency,
        _host      => $host,
        _port      => $port,
    };
    @$self{ keys %$extendent_self } = values %$extendent_self;
    
    $self -> _install_thresholds ($engine_config, \%config);
    $self -> _install_watcher;
    
    return $self;
}

sub start {
    my $self = shift;
    $self->{_callback} //= shift;
    $self->{_w} = AnyEvent->timer(
        after    => 0,
        interval => $self->{_frequency},
        cb       => sub {
            $self->{_watcher}->()
              if defined( $self->{_w} );
        }
    );
}

sub description {
    my $self = shift;
    return "Ping " . $self->{_host} . ":" . $self->{_port};
}

sub _install_watcher {
    my $self = shift;
    my ($host, $port ) = ( $self -> {_host}, $self -> {_port} ); 
    $self -> {_watcher} = sub {
        tcp_connect $host, $port, sub {
            my $success = @_ != 0;
            # $! contains error
            # $host
            # $success
            $self -> _interpret_result( $success, $self->{_callback});
          }, sub {

            #connect timeout
            #my ($fh) = @_;

            1;
          };
    };
}

1;
