use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME  => 'PerlWatcher',
  VERSION   => '0.01',
  MIN_PERL_VERSION  => '5.012000',
  PREREQ_PM => {
    'AnyEvent'              => '7.04',
    'Devel::Comments'       => '1.1.4',
    'File::ReadBackwards'   => '1.05',
    'Gtk2'                  => '1.247',
    'Gtk2::TrayIcon'        => '0.06',
    'Linux::Inotify2'       => '1.22',
    'XML::Simple'           => '2.18',
  },
  TEST_REQUIRES => {
  },
  EXE_FILES => [
    'script/PerlWatcher', 
  ],
  test => {TESTS => 't/*.t'}
);
