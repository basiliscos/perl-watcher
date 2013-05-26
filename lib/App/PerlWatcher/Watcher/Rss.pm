package App::PerlWatcher::Watcher::Rss;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/:levels/;
use AnyEvent::Handle;
use Carp;
use Devel::Comments;
use URI;
use XML::RSSLite;

use base qw(App::PerlWatcher::Watcher);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    my ( $url, $items_count, $frequency, $timeout ) 
        = @config{ qw/ url items frequency timeout / };
        
    croak("url is not defined") unless defined ($url);
    my $uri = URI->new($url);
    
    $items_count //= 5;
    $frequency   //= 60; # once in minute 
    $timeout     //= $engine_config -> {defaults} -> {timeout} // 5;

    my $self = {
        _uri            => $uri,
        _items_count    => $items_count,
        _timeout        => $timeout,
        _frequency      => $frequency,
    };
    bless $self, $class;
    
    #$self -> _install_thresholds ($engine_config, \%config);
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
            $self -> {_watcher}->() if defined( $self -> {_w} );
        }
    );
}

sub description {
    my $self = shift;
    return "Rss::" . $self->{_uri};
}

sub _install_watcher {
    my $self = shift;
    my $uri = $self -> {_uri};
    my ($host, $port ) = ( $uri->host, $uri->port );  
    $self -> {_watcher} = sub {
        my %whole_responce;
        my $handle; $handle = AnyEvent::Handle->new(
            connect => [$host => $port],
            on_error => sub {
                ### on_error
                $handle->destroy;
            },
            on_eof   => sub {
                ### on_eof
                $self -> _handle_result(\%whole_responce);
                $handle->destroy;
            },
        );
        $handle->push_write ("GET $uri HTTP/1.0\015\012\015\012");
        
        
        # now fetch response status line
        $handle->push_read (line => sub {
                my ($handle, $line) = @_;
                $whole_responce{ line } = $line; 
        });
        
        # then the headers
        $handle->push_read (line => "\015\012\015\012", sub {
                my ($handle, $line) = @_;
                $whole_responce{ headers } = $line;
        });
        
        # and finally handle any remaining data as body
        $handle->on_read (sub {
                $whole_responce{ body } .= $_[0]->rbuf;
                $_[0]->rbuf = "";
        });
    };
}

sub _handle_result {
    my ($self, $whole_response) = @_;
    my $content = $whole_response -> {body};
    my %result;
    # $whole_response
    parseRSS(\%result, \$content);
    my @displayed_items = splice @{$result{'item'}}, 0, $self -> {_items_count};
    my $status = App::PerlWatcher::Status->new( 
        $self, LEVEL_NOTICE, sub { 
            $self->description,
        },
        sub {
            my @titles = map {$_ -> {title}} @displayed_items;
            ### @titles
            return ["a","b"];
            #return \@titles;
        },
    );
    # $status
    $self -> {_callback}->($status);    
}


1;
