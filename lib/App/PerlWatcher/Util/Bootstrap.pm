package App::PerlWatcher::Util::Bootstrap;
# ABSTRACT: Collection of various helper-methods to boostrap PerlWatcher

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

=method engine_config

Returns an hash ref of engines' config found in user home named as 'engine.conf'.
If the config file isn't found, than it is been copied from examples/engine.conf.example

=cut

sub engine_config {
    my $config_file = $ARGV[0]
        // get_home_file('engine.conf',
                'App-PerlWatcher-Engine', 'examples/engine.conf.example');
    return config($config_file);
}

=method config

 my $cfg = config('/path/to/config/file');

Parses perlish config file and returns an hash reference to it.

=cut

sub config {
    my ($file) = @_;
    my $content_config = file($file)->slurp(iomode => '<:encoding(UTF-8)');
    my $config = eval "no warnings; $content_config ";
    croak("error in config: $@") if $@ ;
    return $config;
}

=method get_home_file

  my $gtk_config = get_home_file(
            'gtk2.conf',
            'App-PerlWatcher-UI-Gtk2',
            'examples/Gtk2.conf.example',
     );
Gets the file from user's home directory (.perl-watcher) if it is found.
otherwise it is copied to users home from default, which is got via
File::ShareDir, i.e. distirubion name and location in shared files dir.

=cut

sub get_home_file {
    my ($file, $package, $package_example) = @_;
    my $config_file = File::Spec->catfile(get_home_dir(), $file);
    if (not -e $config_file) {
        my $example = dist_file($package, $package_example);
        copy($example, $config_file);
    }
    return $config_file;
}

=method get_home_dir

Returns the path to PerlWatcher home directory (~/.perl-watcher).

=cut

sub get_home_dir {
    my $home = dir(File::Spec->catfile($ENV{'HOME'}, '.perl-watcher'));
    if ( not-X $home ) {
        mkdir $home or croak("can't create $home : $!");
    }
    return $home;
}

1;
