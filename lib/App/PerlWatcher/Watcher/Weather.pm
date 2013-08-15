package App::PerlWatcher::Watcher::Weather;
{
  $App::PerlWatcher::Watcher::Weather::VERSION = '0.12';
}

use 5.12.0;
use strict;
use warnings;
use utf8;

use App::PerlWatcher::EventItem;
use Carp;
use Devel::Comments;               
use HTTP::Date;
use Moo;
use XML::XPath;

our $T_UNITS = {
    celcius => 'C°',
};

has 'latitude'          => ( is => 'ro', required => 1);
has 'longitude'         => ( is => 'ro', required => 1);
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
    my $desc = "Weather ";
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
    $self->_interpret_result(1, $self->callback);
}

sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $callback->($status);
}


1;
