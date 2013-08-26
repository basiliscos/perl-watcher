
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Desktop nagios-inspired events watcher/notifier",
  "dist_author" => [
    "Ivan Baidakou <dmol\@gmx.com>"
  ],
  "dist_name" => "App-PerlWatcher-Engine",
  "dist_version" => "0.14",
  "license" => "perl",
  "module_name" => "App::PerlWatcher::Engine",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => "7.04",
    "AnyEvent::HTTP" => "2.15",
    "Class::Load" => "0.20",
    "Devel::Comments" => "v1.1.4",
    "File::ReadBackwards" => "1.05",
    "File::ShareDir::ProjectDistDir" => "v0.4.4",
    "HTTP::Date" => "6.02",
    "IPC::Run" => "0.92",
    "Linux::Inotify2" => "1.22",
    "List::MoreUtils" => "0.33",
    "Moo" => "1.003000",
    "Path::Class" => "0.32",
    "Storable" => "2.45",
    "URI" => "1.60",
    "XML::Simple" => "2.18",
    "XML::XPath" => "1.13",
    "aliased" => "0.31",
    "perl" => "5.012"
  },
  "script_files" => [],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "AnyEvent::HTTPD" => "0.93",
    "Test::More" => "0.98",
    "Test::TCP" => "1.26"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
