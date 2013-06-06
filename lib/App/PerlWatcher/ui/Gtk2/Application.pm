package App::PerlWatcher::ui::Gtk2::Application;

use 5.12.0;
use strict;
use warnings;

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

    my $tooltips = Gtk2::Tooltips->new;

    $self -> {_icon      } = $icon;
    $self -> {_label     } = $label;
    $self -> {_tooltips  } = $label;          

    $self->_consruct_gui;
    
    my $handler = sub {
        my ($widget, $event) = @_;
        my ($x, $y) = $event->root_coords;
        
        $self->{_window}->hide_all;
        $self->{_window}->move( $x, $y );
        $self->{_window}->show_all;
        $self->{_window}->present;
    };
    
    $icon->signal_connect( "button-press-event" => $handler );

    $label->set_has_tooltip(1);
    $label->set_tooltip_window( $self->{_window} );

    return $self;
}

sub update {
    my ( $self, $statuses ) = @_;
    
    my $model = $self -> {_tree_store };
    $model->update($statuses);
    
    my $max_level = $model->max_actual_level;
    my $symbol = level_to_symbol($max_level);
    $self->_set_label("[$symbol]");
    
    $self->{_treeview   }->expand_all;
}

sub show {
    my $self = shift;
    $self->{_icon}->show_all();
}

sub _set_label {
    my ( $self, $text ) = @_;
    $self->{_label}->set_text($text);
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

1;
