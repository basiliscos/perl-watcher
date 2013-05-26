package App::PerlWatcher::Watcher::Ping;

use 5.12.0;
use strict;
use warnings;

use AnyEvent::Socket;
use App::PerlWatcher::Status qw/string_to_level :levels/;
use App::PerlWatcher::Watcher;
use Carp;
use Clone qw(clone);
use Devel::Comments;
use Hash::Merge qw( merge );
use List::Util qw( first );

use base qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    my ( $host, $port, $frequency, $timeout ) 
        = @config{ qw/ host port frequency timeout / };
        
    croak("host is not defined") unless defined ($host);
    croak("port is not defined") unless defined ($port);
    
    $frequency  //= 60;
    $timeout    //= $engine_config -> {defaults} -> {timeout} // 5;

    my $self = {
        _frequency => $frequency,
        _host      => $host,
        _port      => $port,
    };
    bless $self, $class;
    
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
            $self->{_watcher}->( $self->{_callback} )
              if defined( $self->{_w} );
        }
    );
}

sub description {
    my $self = shift;
    return "Ping " . $self->{_host} . ":" . $self->{_port};
}

sub _result_as_metakey {
    my ($self, $result) = @_;
    return !$result ? 'fail' : 'ok';
}

sub _interpret_result {
    my ($self, $result, $callback ) = @_;
    my $thresholds = $self -> {_threshold};
    $self -> {_last_result} //= $result;
    my $meta_key     = $self -> _result_as_metakey( $result );
    my $opposite_key = $self -> _result_as_metakey( !$result );
    
    my $counter_key          =  "_$meta_key" . "_counter";
    my $opposite_counter_key =  "_$opposite_key" . "_counter";
    
    my $counter = $self -> {$counter_key}++;
    $self -> {$opposite_counter_key} = 0 if ($self -> {_last_result} != $result);
    
    $self -> {_last_level} //= LEVEL_NOTICE;
    
    my @levels = sort keys (%{ $thresholds -> {$meta_key} });
    my $level_key = first { $_ >= $counter } @levels;
    # $level_key
    if ( defined $level_key ) {
        $self -> {_last_level} = $thresholds -> {$meta_key} -> {$level_key};
    }
    my $level = $self -> {_last_level};
    my $status = App::PerlWatcher::Status->new( 
        $self, $level, sub { 
            $self->description 
        },
    );
    # $status
    $callback->($status);    
}

sub _install_thresholds {
    my ( $self, $engine_config, $config ) = @_;
    my ( $r, $l ) = (
        clone( $engine_config -> {defaults} -> {behaviour} ),
        clone( $config        -> {on} // {} ),
    );
    my $threshold = merge( $r, $l );
    # merging
    ## $threshold
    ## $l
    ## $r
    for my $k ('ok', 'fail') {
        while (my ($key, $value) = each %{ $threshold -> {$k} } ) {
            ## $k
            ## $key
            ## $value
            my $right = _key_for_value( $value, %{ $r->{$k} } );
            my $left  = _key_for_value( $value, %{ $l->{$k} } );
            ## $right
            ## $left
            delete $threshold -> {$k} -> {$right} 
                if ( defined($right) && defined($left) );
        }
    }
    ## $threshold
    #changing from human-readable to numeric values
    for my $k ('ok', 'fail') {
        while (my ($key, $value) = each %{ $threshold -> {$k} } ) {
            $threshold -> {$k} -> {$key} 
                = string_to_level( $value );
        }
    }
    ## $threshold
    $self -> {_threshold} = $threshold; 
}

sub _key_for_value {
    my ($target, %h) = @_;
    my %reversed = reverse %h;
    return $reversed{ $target } ;
}

sub _install_watcher {
    my $self = shift;
    my ($host, $port ) = ( $self -> {_host}, $self -> {_port} ); 
    $self -> {_watcher} = sub {
        my $callback = shift;
        tcp_connect $host, $port, sub {
            my $success = @_;
            # $! contains error
            ### $host
            ### $success
            $self -> _interpret_result(scalar @_, $callback );
          }, sub {

            #connect timeout
            #my ($fh) = @_;

            1;
          };
    };
}

1;
