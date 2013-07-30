package App::PerlWatcher::Watcher::HTTPSimple;
{
  $App::PerlWatcher::Watcher::HTTPSimple::VERSION = '0.11';
}

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::EventItem;
use Carp;
use Devel::Comments;
use Moo;
use URI;

has 'url'                   => ( is => 'ro', required => 1);
has 'response_handler'      => ( is => 'ro', required => 1);
has 'processed_response'    => ( is => 'rw');

extends qw/App::PerlWatcher::Watcher::HTTP/;

sub description {
    my $self = shift;
    my $desc = "HTTP [" . $self->title . "]";
    my $response = $self->processed_response;
    $desc .= " : " . ( $response // q{} );
    return $desc;
}

sub process_http_response {
    my ($self, $content, $headers) = @_;
    my ($result, $success) = (undef, 0);
    
    eval {
        $result = $self->response_handler->(local $_ = $content);
        $success = 1;
    };
    $result = $@ if($@);
    
    # $result
    # $success
    $self->processed_response($result);
    $self->_interpret_result($success, $self->callback);
}

1;
