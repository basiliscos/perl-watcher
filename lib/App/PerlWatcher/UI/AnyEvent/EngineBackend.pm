package App::PerlWatcher::UI::AnyEvent::EngineBackend;
{
  $App::PerlWatcher::UI::AnyEvent::EngineBackend::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;

use AnyEvent;

sub new {
    my $class = shift;
    my $self = {};
    return bless $self => $class;
}

sub start_loop {
    my $self = shift;
    $self->{_app_stop} = AnyEvent->condvar;
    $self->{_app_stop}->recv;
}

sub stop_loop {
    my $self = shift;
    $self->{_app_stop}->send;
}

1;

__END__

=pod

=head1 NAME

App::PerlWatcher::UI::AnyEvent::EngineBackend

=head1 VERSION

version 0.12

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
