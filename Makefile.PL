
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.72;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Desktop nagios-inspired events watcher/notifier",
  "AUTHOR" => "Ivan Baidakou <dmol\@gmx.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.72",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "App-PerlWatcher-Engine",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::PerlWatcher::Engine",
  "PREREQ_PM" => {
    "AnyEvent" => "7.04",
    "AnyEvent::HTTP" => "2.15",
    "Class::Load" => "0.20",
    "Data::Dump" => "1.22",
    "Devel::Comments" => "v1.1.4",
    "File::ReadBackwards" => "1.05",
    "File::ShareDir::ProjectDistDir" => "v0.4.4",
    "HTTP::Date" => "6.02",
    "IPC::Run3" => "0.046",
    "Linux::Inotify2" => "1.22",
    "List::MoreUtils" => "0.33",
    "Moo" => "1.003000",
    "Net::Ping::External" => "0.13",
    "Path::Class" => "0.32",
    "Storable" => "2.45",
    "URI" => "1.60",
    "XML::Simple" => "2.18",
    "XML::XPath" => "1.13",
    "aliased" => "0.31"
  },
  "TEST_REQUIRES" => {
    "AnyEvent::HTTPD" => "0.93",
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0,
    "Test::TCP" => "1.26"
  },
  "VERSION" => "0.16_3",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


