package App::PerlWatcher::ui::Gtk2::Application;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use App::PerlWatcher::Status qw/level_to_symbol :levels/;
use App::PerlWatcher::ui::Gtk2::StatusesModel;
use App::PerlWatcher::ui::Gtk2::StatusesTreeView;
use Devel::Comments;
use Gtk2;
use Gtk2::TrayIcon;
use POSIX qw(strftime);

use base qw/App::PerlWatcher::Frontend/;

sub new {
    my ( $class, $engine ) = @_;
    my $self = $class->SUPER::new($engine);
    
    Gtk2->init;
    my $icon      = Gtk2::TrayIcon->new("test");
    my $event_box = Gtk2::EventBox->new;

    my $label = Gtk2::Label->new("test");
    $event_box->add($label);
    $icon->add($event_box);

    $self -> {_icon      } = $icon;
    $self -> {_label     } = $label;
    $self -> {_timers    } = [];          

    $self->_consruct_gui;
    
    $icon->signal_connect( "button-press-event" => sub {
        my ($widget, $event) = @_;
        my ($x, $y) = $event->root_coords;
        $self -> _present($x, $y);
    });

    #$label->set_has_tooltip(1);
    #$label->set_tooltip_window( $self->{_window} );

    return $self;
}

sub update {
    my ( $self, $status ) = @_;
    my $visible = $self->{_window}->get('visible');
    my $model = $self->{_tree_store};
    $model->update($status, $visible);
    $self->{_treeview}->expand_all;
    $self->_trigger_undertaker if ( $visible );
    $self->_update_summary;
}
                                  
sub show {
    my $self = shift;
    $self->{_icon}->show_all();
}

sub _update_summary {
    my $self = shift;
    my $summary = $self->{_tree_store}->summary;
    # $summary
    my $symbol = level_to_symbol($summary->{max_level});
    $symbol = @{ $summary->{updated} } ? "<b>$symbol</b>" : $symbol;
    my $sorted_statuses = $self->engine->sort_statuses($summary->{updated});
    $symbol = "[$symbol]";
    my $tip = join "\n", map {
            sprintf("[%s] %s", level_to_symbol($_->level), $_->description->())
        } @$sorted_statuses;
    $self->_set_label($symbol, $tip);
}

sub _set_label {
    my ( $self, $text, $tip ) = @_;
    $self->{_label}->set_markup($text);
    $self->{_label}->set_tooltip_markup($tip);
}

sub _construct_window {
    my $self   = shift;
    my $window = Gtk2::Window->new;

    my $default_size =
      $self->engine->config->{frontend}->{gtk}->{window_size}
      // [ 500, 300 ];

    $window->set_default_size(@$default_size);
    $window->set_title('Title');

    #$window -> set_decorated(0);
    #$window -> set_opacity(0); # not works yet
    $window->set_skip_taskbar_hint(1);
    $window->set_type_hint('tooltip');
    $window->signal_connect( delete_event => \&Gtk2::Widget::hide_on_delete );
    $window->signal_connect( 'focus-out-event' => sub {
            ### focus out
            $window->hide;
            $self->{_timers} = []; # kill all timers
            $self->last_seen(time);
    });

    return $window;
}

sub _consruct_gui {
    my $self = shift;
    my $window = $self->_construct_window;

    my $vbox = Gtk2::VBox->new( 0, 6 );
    $window->add($vbox);

    my $label = Gtk2::Label->new('Hello World!');
    $vbox->pack_start( $label, 1, 1, 0 );

    my $tree_store = App::PerlWatcher::ui::Gtk2::StatusesModel
        ->new($self);
    my $treeview   = App::PerlWatcher::ui::Gtk2::StatusesTreeView
        ->new($tree_store, $self);
    $vbox->pack_start( $treeview, 1, 1, 0 );                       
    
    $vbox->show_all;

    $self->{_custom_widget} = $vbox;
    $self->{_window}        = $window;
    $self->{_tree_store}    = $tree_store;
    $self->{_treeview}      = $treeview;
}

sub _present {
    my ( $self, $x, $y ) = @_;
    my $window = $self->{_window}; 
    if ( !$window->get('visible') ) {
        $window->hide_all;
        $window->move( $x, $y );
        $window->show_all;
        $window->present;
        $self->_trigger_undertaker;
    }
}

sub _trigger_undertaker {
    my $self = shift;
    my $idle = 
        $self->engine->config->{frontend}->{gtk}->{uninteresting_after} // 5;
    my $now = time;
    my $timer = AnyEvent->timer (
        after => $idle,
        cb    => sub {
            $self->{_tree_store}->stash_outdated($now);
            $self->_update_summary;
        },
    );                                       
    push @{ $self->{_timers} }, $timer;
}

1;
