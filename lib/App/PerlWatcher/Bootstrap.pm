package App::PerlWatcher::Bootstrap;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Class::Load ':all';
use File::ShareDir ':ALL';

use parent qw/Exporter/;

our @EXPORT_OK = qw/startup frontend/;

sub startup {
    #my $file = dist_file('samples',  'config/PerlWatcher.conf.sample');
    
    my $config_file = $ARGV[0];

    open(my $config_fh, "<", $config_file) 
        or croak("Can't open config file $config_file");
    
    my $content_config = do { local $/ = <$config_fh> };
    my $config = eval "no warnings; $content_config ";
    croak("error in config: $@") if $@ ;
    return $config;
}

sub frontend {
    my ($hint, $engine) = @_;
    my $fe_class = "App::PerlWatcher::ui::" . $hint . "::Application"; 
    my $app = eval {
        load_class($fe_class);
        return $fe_class->new($engine);
    };
    croak "Error creating application $fe_class : $@" if $@;
    return $app;
}

1;
