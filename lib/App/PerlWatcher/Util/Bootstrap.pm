package App::PerlWatcher::Util::Bootstrap;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Class::Load ':all';
use File::Copy;
use File::ShareDir::ProjectDistDir ':all';
use File::Spec;
use Path::Class qw(file dir);

use parent qw/Exporter/;

our @EXPORT_OK = qw/engine_config get_home_file get_home_dir config/;

sub engine_config {
    my $config_file = $ARGV[0] 
        // get_home_file('engine.conf', 
                __PACKAGE__, 'examples/engine.conf.example');
    return config($config_file);
}

sub config {
    my ($file) = @_;
    my $content_config = file($file)->slurp(iomode => '<:encoding(UTF-8)'); 
    my $config = eval "no warnings; $content_config ";
    croak("error in config: $@") if $@ ;
    return $config;    
}

# with fallback to packages's default file
sub get_home_file {
    my ($file, $package, $package_example) = @_;
    my $config_file = File::Spec->catfile(get_home_dir(), $file);
    if (not -e $config_file) {
        my $example = dist_file($package, $package_example);
        copy($example, $config_file);
    }
    return $config_file;
}

sub get_home_dir {
    my $home = dir(File::Spec->catfile($ENV{'HOME'}, '.perl-watcher'));
    if ( not-X $home ) {
        mkdir $home or croak("can't create $home : $!");
    }
    return $home;
}

1;
