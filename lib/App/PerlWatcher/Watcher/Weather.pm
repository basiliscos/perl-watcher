package App::PerlWatcher::Watcher::Weather;
# ABSTRACT: Weather watches based around api.yr.no. Currenlty monitors only temperature and does no any notifications / level alerts.

use 5.12.0;
use strict;
use warnings;
use utf8;

use App::PerlWatcher::EventItem;
use Carp;
use Function::Parameters qw(:strict);
use Moo;
use Smart::Comments -ENV;
use XML::XPath;

our $T_UNITS = {
    celcius => 'C°',
};

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

=cut

=attr latitude

The location latitude

=cut

has 'latitude'          => ( is => 'ro', required => 1);

=attr longitude

The location longitude

=cut

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

method _build_url {
    return $self->url_generator->($self->latitude, $self->longitude);
}

method description {
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

method process_http_response($content, $headers) {
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

1;
