
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
    "File::ReadBackwards" => "1.05",
    "File::ShareDir::ProjectDistDir" => "v0.4.4",
    "IPC::Cmd" => "0.90",
    "IPC::Run3" => "0.045",
    "List::MoreUtils" => "0.33",
    "Moo" => "1.003000",
    "Net::Ping::External" => "0.13",
    "Path::Tiny" => "0.049",
    "Smart::Comments" => "1.000004",
    "Storable" => "2.45",
    "URI" => "1.60",
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
    "Test::TCP" => "1.26",
    "Test::Warnings" => "0.013"
  },
  "VERSION" => "0.20",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "AnyEvent" => "7.04",
  "AnyEvent::HTTP" => "2.15",
  "AnyEvent::HTTPD" => "0.93",
  "Class::Load" => "0.20",
  "Data::Dump" => "1.22",
  "File::ReadBackwards" => "1.05",
  "File::ShareDir::ProjectDistDir" => "v0.4.4",
  "File::Spec" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "IPC::Cmd" => "0.90",
  "IPC::Open3" => 0,
  "IPC::Run3" => "0.045",
  "List::MoreUtils" => "0.33",
  "Moo" => "1.003000",
  "Net::Ping::External" => "0.13",
  "Path::Tiny" => "0.049",
  "Smart::Comments" => "1.000004",
  "Storable" => "2.45",
  "Test::More" => 0,
  "Test::TCP" => "1.26",
  "Test::Warnings" => "0.013",
  "URI" => "1.60",
  "XML::XPath" => "1.13",
  "aliased" => "0.31"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


