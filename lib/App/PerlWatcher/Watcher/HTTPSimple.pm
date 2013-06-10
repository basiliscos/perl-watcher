package App::PerlWatcher::Watcher::HTTPSimple;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/:levels/;
use App::PerlWatcher::EventItem;
use Carp;
use Devel::Comments;
use URI;

use base qw(App::PerlWatcher::Watcher::HTTP);

sub new {
    my ( $class, $engine_config, %config ) = @_;
    
    my $response_handler = $config{'response_handler'};
    croak("response_handler is not defined") unless defined ($response_handler);
    
    $config{processor} = \&_process_http;
    my $self = $class->SUPER::new($engine_config, %config);
    
    $self->{_response_handler} = $response_handler;
    
    return $self;
}

sub description {
    my $self = shift;
    my $desc = "HTTP [" . $self->{_title} . "]";
    $desc .= " : " . ( $self->{_processed_response} // q{} );
    return $desc;
}

sub _process_http {
    my ($self, $content, $headers) = @_;
    my ($result, $success) = (undef, 0);
    
    eval {
        $result = $self->{_response_handler}->(local $_ = $content);
        $success = 1;
    };
    $result = $@ if($@);
    
    # $result
    # $success
    $self->{_processed_response} = $result;
    $self->_interpret_result($success, $self -> {_callback});
}

1;
