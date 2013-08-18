package App::PerlWatcher::Watcher::HTTPSimple;
{
  $App::PerlWatcher::Watcher::HTTPSimple::VERSION = '0.12';
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

with qw/App::PerlWatcher::Watcher::HTTP/;

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
    $self->interpret_result($success, $self->callback);
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Watcher::HTTPSimple

=head1 VERSION

version 0.12

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
