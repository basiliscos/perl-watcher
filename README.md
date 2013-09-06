# PerlWatcher

![Build status](https://api.travis-ci.org/basiliscos/perl-watcher.png "Build status")

## Description

Nagios-inspired system tray events desktop watcher / notifier. The main
difference, that it is desktop application.

There is too many programs (system update, news, weather etc), which notify
you about it via it's own style.

Do you need to track and aggregate events from the different sources?
PerlWatcher can do simplified infrastructure monitoring (pinging them),
track stock quotes, weather, new software updates, poll the remote VCS
for RSS updates, be notified by local news or by some changes on your
/var/log/messages? Do you want to have possibility to easily write your own
event-watcher in the case you local media-content provider does not have any
API no notify you about new films and you fill yourself hackish enough to do
some reverse engineering for writing your watcher?

If yes, than PerlWatcher is designed for that purpose.

PerlWatcher supports also an different levels of notification: "notice",
"info" .. "alert". They indicate how important the event is for you: if you are
doing an boring task it's natural to switch attention to anything else for
couple of seconds; but if the task is serious you can rise the notification
level to 'alert' to be disturbed only by blackout on remote servers :)

It looks like (Gtk2 UI):

![PerlWatcher GTK2 screenshot](https://raw.github.com/basiliscos/images/master/PerlWatcher-0.12.png "PerlWatcher GTK2 screenshot")


## PerlWatcher and RSS-Aggregator

PerlWatcher isn't designed to be fully functional RSS-Aggregator, because:
* RSS-feeds news often aren't complete as web version, because web-masters
need you to go to the site and see the banners. It isn't very pleasant to
read only the half part of the news, and then go to the site to see the
full version.
* PerlWatcher is designed to be lightweight: displaying simple text (headers)
is enough for that, while showing the HTML with images isn't so.

## Installation

Install perl and cpan-minus https://metacpan.org/module/App::cpanminus#INSTALLATION .
The most easy way to do that is just do
```
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
```

Now it is time to intall PerlWatcher itself

```
cpanm App::PerlWatcher::Engine
cpanm App::PerlWatcher::UI::Gtk2
cpanm App::PerlWatcher::Watcher::FileTail
```

### Running (GTK2-frontend)
```
perl-watcher-gtk
```

Edit ~/.perl-watcher/engine.conf and add/modify watchers like:

```
        {
            class => 'App::PerlWatcher::Watcher::Ping',
            config => {
                host    =>  'google.com',
                port    =>  80,
                frequency   =>  10,
                on => { fail => { 5 => 'alert' } },
            },
        },

        {
            class => 'App::PerlWatcher::Watcher::Rss',
            config => {
                url         =>  'http://www.opennet.ru/opennews/opennews_all.rss',
                title       =>  'opennet',
                frequency   => 60,
                timeout     => 10,
                items       =>  5,
                on          => {
                        ok      => { 1  => 'notice' },
                        fail    => { 10 => 'info/max' },
                },
            },
        },

```
Explanation: here the PerlWatcher will 
* montitor google.com by pinging it's port 80 every 10 seconds, and after 5 
unsuccessfull pings it will set status 'alert'; 
* fetch top 5 news from opennet.ru every minute, and in case of 10 failures it
will set 'info' status to the watcher.

## Development

Any help, critique, suggestions, requests, advises... are welcome. Especially,
I have troubles with Gtk2 UI.

Current road map can be found here https://github.com/basiliscos/perl-watcher/blob/master/TODO

## Design

PerlWatcher is written in Modern Perl using AnyEvent and Moo.

PerlWatcher is composed of Engine (including basic watchers) and UI. Watchers are
completly decoupled from UI, so it should be possible to use any possible Watcher
with any UI. Currently UI frontend use GTK2+, but it should be easy to use the others, 
like: KDE, console or even aggregate it as tmux-extension.


## COPYRIGHT AND LICENSE

    This software is copyright (c) 2013 by Ivan Baidakou.

    This is free software; you can redistribute it and/or modify it under
    the same terms as the Perl 5 programming language system itself.
