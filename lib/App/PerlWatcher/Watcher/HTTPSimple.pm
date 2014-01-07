package App::PerlWatcher::Watcher::HTTPSimple;
{
  $App::PerlWatcher::Watcher::HTTPSimple::VERSION = '0.20';
}
# ABSTRACT: The simple HTTP watcher, where actual http responce body is been processed by closure

use 5.12.0;
use strict;
use warnings;
use utf8;

use App::PerlWatcher::EventItem;
use Carp;
use Function::Parameters qw(:strict);
use Moo;
use Smart::Comments -ENV;
use Types::Standard qw/Str Num CodeRef/;
use URI;



has 'url' => ( is => 'ro', required => 1, isa => Str);


has 'response_handler' => ( is => 'ro', required => 1, isa => CodeRef);


has 'processed_response' => ( is => 'rw', isa => Str);

with qw/App::PerlWatcher::Watcher::HTTP/;

method description {
    my $desc = "HTTP [" . $self->title . "]";
    my $response = $self->processed_response;
    $desc .= " : " . ( $response // q{} );
    return $desc;
}

method process_http_response($content, $headers) {
    my ($result, $success) = (undef, 0);

    eval {
        $result = $self->response_handler->(local $_ = $content);
        $success = 1;
    };
    $result = $@ if($@);

    # $result
    # $success
    $self->processed_response($result);
    $self->interpret_result($success, $self->callback);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlWatcher::Watcher::HTTPSimple - The simple HTTP watcher, where actual http responce body is been processed by closure

=head1 VERSION

version 0.20

=head1 SYNOPSIS

 # use the following config for Engine:

 {
   class => 'App::PerlWatcher::Watcher::HTTPSimple',
   config => {
     url                 =>  'http://download.finance.yahoo.com/d/quotes.csv?s=EURUSD=X&f=sl1d1t1c1ohgv&e=.csv',
     title               =>  '€/$',
     frequency           => 600,
     timeout             => 10,
     response_handler    => sub {
        (split(',', $_))[1];
     },
     on                  => {
        ok      => { 1  => 'notice' },
        fail    => { 10 => 'info'   },
     },
    },
 },

=head1 ATTRIBUTES

=head2 url

The url been wached

=head2 response_handler

The callback, which is been called as response_handler($body), and
which should return the body to be displayed as result.

=head2 processed_response

The last result, which is been stored after invocation of response_handler

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
