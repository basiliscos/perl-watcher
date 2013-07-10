package App::PerlWatcher::Watcher::Weather;

use 5.12.0;
use strict;
use warnings;
use utf8;

use App::PerlWatcher::Status qw/:levels/;
use App::PerlWatcher::EventItem;
use Carp;
use Devel::Comments;
use HTTP::Date;
use XML::XPath;

use base qw(App::PerlWatcher::Watcher::HTTP);

our $T_UNITS = {
    celcius => 'C°',
};
    

sub new {
    my ( $class, $engine_config, %config ) = @_;
    
    my $url_generator = $config{url_generator} // sub {
        my ($lat, $lon) = @_;
        return "http://api.yr.no/weatherapi/locationforecast/1.8/?lat=$lat;lon=$lon";
    };
    
    croak "latitude is not defined" unless $config{latitude};
    croak "longitude is not defined" unless $config{longitude};
    
    $config{url      } = $url_generator->($config{latitude}, $config{longitude});
    $config{processor} = \&_process_reply;
    
    my $self = $class->SUPER::new($engine_config, %config);
    return $self;
}

sub description {
    my $self = shift;
    my $desc = "Weather ";
    my %data = %{ $self->{_data} // {} }; 
    if ( %data ) {
        $desc .= join(q{, } , 
            map { $_ . ": " . $data{$_} }
            sort keys (%data)
        );
    }
    return $desc;
}

sub _process_reply {
    my ($self, $content, $headers) = @_;
    my $xp = XML::XPath->new(xml => $content);
    my $t_node = $xp->find('//time[1]/location/temperature');
    if ($t_node) {
        my $t_item = $t_node->shift;
        my $value = $t_item->find('string(./@value)');
        my $unit = $t_item->find('string(./@unit)');
        $self->{_data}{t} = sprintf("%s%s", $value, $T_UNITS->{$unit});
    }
    $self->_interpret_result(1, $self -> {_callback});
}

sub _invoke_callback {
    my ($self, $callback, $status) = @_;
    $callback->($status);
}


1;
