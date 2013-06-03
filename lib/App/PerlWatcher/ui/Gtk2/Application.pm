package App::PerlWatcher::ui::Gtk2::Application;

use 5.12.0;
use strict;
use warnings;

use App::PerlWatcher::Status qw/level_to_symbol :levels/;
use Data::Dumper;
use Devel::Comments;
use Gtk2;
use Gtk2::TrayIcon;
use POSIX qw(strftime);

sub new {
    my ( $class, $engine ) = @_;
    Gtk2->init;
    my $icon      = Gtk2::TrayIcon->new("test");
    my $event_box = Gtk2::EventBox->new;

    my $label = Gtk2::Label->new("test");
    $event_box->add($label);
    $icon->add($event_box);

    my $tooltips = Gtk2::Tooltips->new;

    my $self = {
        _icon     => $icon,
        _label    => $label,
        _tooltips => $tooltips,
        _engine   => $engine,
    };
    bless $self, $class;

    $self->_consruct_gui;
    
    $self -> {_last_seen} = 0;
    my $handler = sub {
        my ( $widget, $event ) = @_;
        $self->{_window}->hide_all;
        my ( $x, $y ) = $event->root_coords;
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
    my $symbol      = $self->_result_to_symbol($statuses);
    my $description = $self->_result_to_description($statuses);
    $self->_set_label("[$symbol]");
    $self->_update_model($statuses);
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
      $self->{_engine}->config->{frontend}->{gtk}->{window_size}
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
            $self -> {_last_seen} = time;
    });

    return $window;
}

sub _is_unseen {
    my ($self, $status) = @_;
    my $r = 0;
    if ($status->updated 
        && ($status->timestamp > $self -> {_last_seen}) ) {
        $r = 1;
    }
    return $r;
}

sub _consruct_gui {
    my $self = shift;

    my $window = $self->_construct_window;

    my $vbox = Gtk2::VBox->new( 0, 6 );
    $window->add($vbox);

    my $label = Gtk2::Label->new('Hello World!');
    $vbox->pack_start( $label, 1, 1, 0 );

    my $tree_store = Gtk2::TreeStore->new(qw/Glib::Scalar/);
    my $treeview   = Gtk2::TreeView->new($tree_store);
    $vbox->pack_start( $treeview, 1, 1, 0 );

    # 1st col
    my $renderer_desc = Gtk2::CellRendererText->new;
    $renderer_desc->set( ellipsize => 'end', 'width-chars' => 100 );

    my $column_desc = Gtk2::TreeViewColumn->new;
    $column_desc->pack_start( $renderer_desc, 0 );
    $column_desc->set_title('_description');
    $treeview->append_column($column_desc);
    $column_desc->set_cell_data_func(
        $renderer_desc,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            my $text;
            if ( $value->isa('App::PerlWatcher::Status') ) {
                my $status = $value;
                $text = sprintf( "[%s] %s",
                    $status->symbol, $status->description->() );
                $text = "<b>$text</b>" if ($self->_is_unseen($status));
                $cell->set( markup => "$text" );
            }
            else {
                $cell->set( text => $value -> content );
            }
            
        }
    );

    # 2nd col
    my $renderer_toggle = Gtk2::CellRendererToggle->new;
    $renderer_toggle->set( activatable => 1 );
    $renderer_toggle->signal_connect(
        "toggled" => sub {
            my ( $renderer, $path ) = @_;
            ## $path
            my $iter           = $tree_store->get_iter_from_string($path);
            my $status         = $tree_store->get_value( $iter, 0 );
            my $w              = $status->watcher;
            my $current_active = $w->active;
            $w->active( !$current_active );
        },
        $tree_store
    );

    # 3rd col
    my $column_toggle = Gtk2::TreeViewColumn->new;
    $column_toggle->pack_start( $renderer_toggle, 1 );
    $column_toggle->set_title('_active');
    $treeview->append_column($column_toggle);
    $column_toggle->set_cell_data_func(
        $renderer_toggle,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            if ( $value->isa('App::PerlWatcher::Status') ) {
                my $status = $value;
                $cell->set( active  => $status->watcher->active );
                $cell->set( visible => 1 );
            }
            else {
                $cell->set( visible => 0 );
            }

        }
    );
    
    # 3rd col
    my $renderer_timestamp = Gtk2::CellRendererText->new;
    my $column_timestamp = Gtk2::TreeViewColumn->new;
    $column_timestamp->pack_start( $renderer_timestamp, 2 );
    $column_timestamp->set_title('_timestamp');
    $treeview->append_column($column_timestamp);
    $column_timestamp->set_cell_data_func(
        $renderer_timestamp,
        sub {
            my ( $column, $cell, $model, $iter, $func_data ) = @_;
            my $value = $model->get_value( $iter, 0 );
            my $timestamp = $value->timestamp;
            my $text = $timestamp ? strftime('%H:%M:%S',localtime $timestamp) 
                                  : q{}
                                  ;
            ## $text
            $cell->set( text => $text );
        }
    );

    $vbox->show_all;

    $self->{_custom_widget} = $vbox;
    $self->{_window}        = $window;
    $self->{_tree_store}    = $tree_store;
    $self->{_treeview}      = $treeview;
}

sub _update_model {
    my ( $self, $statuses ) = @_;
    my $tree_store = $self->{_tree_store};
    $tree_store->clear;
    for (@$statuses) {
        my $iter   = $tree_store->append(undef);
        my $label  = sprintf( "[%s] %s", $_->symbol, $_->description->() );
        my $active = $_->watcher->active;
        $tree_store->set( $iter, 0 => $_ );
        my $items = $_->items ? $_->items->() : [];
        for my $i (@$items) {
            my $iter_child = $tree_store->append($iter);
            $tree_store->set( $iter_child, 0 => $i );
        }
    }
    $self->{_treeview}->expand_all;
}

sub _result_to_description {
    my ( $self, $statuses ) = @_;

    my $description = "";
    $description .= sprintf( "[%s] %s\n", $_->symbol, $_->description->() )
      for @$statuses;
    chomp $description;

    return $description;
}

sub _result_to_symbol {
    my ( $self, $statuses ) = @_;
    my $level = LEVEL_ANY;
    for my $status (@$statuses) {
        $level = $status->level if $level < $status->level; 
    }
    my $symbol = level_to_symbol($level);
    return $symbol;
}

1;
