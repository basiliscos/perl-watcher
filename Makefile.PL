use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME  => 'PerlWatcher',
  VERSION   => '0.03',
  MIN_PERL_VERSION  => '5.012000',
  PREREQ_PM => {
    'AnyEvent'              => '7.04',
    'AnyEvent::HTTP'        => '2.15',
    'Devel::Comments'       => '1.1.4',
    'HTTP::Date'            => '6.02',
    'File::ReadBackwards'   => '1.05',
    'Gtk2'                  => '1.247',
    'Gtk2::TrayIcon'        => '0.06',
    'Linux::Inotify2'       => '1.22',
    'XML::Simple'           => '2.18',
  },
  TEST_REQUIRES => {
      'Test::HTTP::Server'  => '0.03',
  },
  EXE_FILES => [
    'script/PerlWatcher', 
  ],
  test => {TESTS => 't/*.t'}
);
