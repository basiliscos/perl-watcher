use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.036

use Test::More  tests => 19 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'App/PerlWatcher/Backend.pm',
    'App/PerlWatcher/Describable.pm',
    'App/PerlWatcher/Engine.pm',
    'App/PerlWatcher/EventItem.pm',
    'App/PerlWatcher/Frontend.pm',
    'App/PerlWatcher/Level.pm',
    'App/PerlWatcher/Levels.pm',
    'App/PerlWatcher/Openable.pm',
    'App/PerlWatcher/Shelf.pm',
    'App/PerlWatcher/Status.pm',
    'App/PerlWatcher/Util/Bootstrap.pm',
    'App/PerlWatcher/Util/Storable.pm',
    'App/PerlWatcher/Watcher.pm',
    'App/PerlWatcher/Watcher/GenericExecutor.pm',
    'App/PerlWatcher/Watcher/HTTP.pm',
    'App/PerlWatcher/Watcher/HTTPSimple.pm',
    'App/PerlWatcher/Watcher/Ping.pm',
    'App/PerlWatcher/Watcher/Weather.pm',
    'App/PerlWatcher/WatcherMemory.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my $inc_switch = q[-Mblib];

use File::Spec;
use IPC::Open3;
use IO::Handle;

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


