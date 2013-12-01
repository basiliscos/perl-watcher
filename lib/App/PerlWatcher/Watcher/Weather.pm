package App::PerlWatcher::Watcher::Weather;
{
  $App::PerlWatcher::Watcher::Weather::VERSION = '0.18_2'; # TRIAL
}
# ABSTRACT: Weather watches based around api.yr.no. Currenlty monitors only temperature and does no any notifications / level alerts.

use 5.12.0;
use strict;
use warnings;
use utf8;

use App::PerlWatcher::EventItem;
use Carp;
use Smart::Comments -ENV;
use Moo;
use XML::XPath;

our $T_UNITS = {
    celcius => 'C°',
};



has 'latitude'          => ( is => 'ro', required => 1);


has 'longitude'         => ( is => 'ro', required => 1);

# for internal usage

has 'data'              => ( is => 'rw', default => sub{ {}; } );
has 'url_generator'     => ( is => 'lazy');
has 'url'               => ( is => 'lazy');

with qw/App::PerlWatcher::Watcher::HTTP/;

sub _build_url_generator {
    return sub {
        my ($lat, $lon) = @_;
        return "http://api.yr.no/weatherapi/locationforecast/1.8/?lat=$lat;lon=$lon";
    };
}

sub _build_url {
    my $self = shift;
    return $self->url_generator->($self->latitude, $self->longitude);
}

sub description {
    my $self = shift;
    my $desc = "";
    my %data = %{ $self->data // {} };
    if ( %data ) {
        $desc .= join(q{, } ,
            map { $_ . ": " . $data{$_} }
            sort keys (%data)
        );
    }
    return $desc;
}

sub process_http_response {
    my ($self, $content, $headers) = @_;
    my $xp = XML::XPath->new(xml => $content);
    my $t_node = $xp->find('//time[1]/location/temperature');
    if ($t_node) {
        my $t_item = $t_node->shift;
        my $value = $t_item->find('string(./@value)');
        my $unit = $t_item->find('string(./@unit)');
        $self->data->{t} = sprintf("%s%s", $value, $T_UNITS->{$unit});
    }
    $self->interpret_result(1, $self->callback);
}

sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $callback->($status);
}


1;

__END__

=pod

=head1 NAME

App::PerlWatcher::Watcher::Weather - Weather watches based around api.yr.no. Currenlty monitors only temperature and does no any notifications / level alerts.

=head1 VERSION

version 0.18_2

=head1 SYNOPSIS

 # use the following config for Engine:
        {
            class => 'App::PerlWatcher::Watcher::Weather',
            config => {
                describer   => sub { "Weather in Minsk: " . $_[0] },
                latitude    => 53.54,
                longitude   => 27.34,
                frequency   => 1800,
                timeout     => 15,
            },
        },

=head1 ATTRIBUTES

=head2 latitude

The location latitude

=head2 longitude

The location longitude

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
