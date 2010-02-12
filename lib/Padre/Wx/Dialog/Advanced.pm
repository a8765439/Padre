package Padre::Wx::Dialog::Advanced;

use 5.008;
use strict;
use warnings;
use Padre::Wx                  ();
use Padre::Wx::Role::MainChild ();
use Padre::Config              ();

our $VERSION = '0.56';
our @ISA     = qw{
	Padre::Wx::Role::MainChild
	Wx::Dialog
};

=pod

=head1 NAME

Padre::Wx::Dialog::Advanced - a dialog to show and configure advanced preferences

=head1 DESCRIPTION

The idea is to implement a Mozilla-style about:config for Padre. This will make
playing with experimental, advanced, and sekrit settings a breeze.

=head1 PUBLIC API

=head2 C<new>

  my $advanced = Padre::Wx::Dialog::Advanced->new($main);

Returns a new C<Padre::Wx::Dialog::Advanced> instance

=cut

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the Wx dialog
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Advanced Settings'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE,
	);

	# Minimum dialog size
	$self->SetMinSize( [ 500, 550 ] );

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);

	# Create the controls
	$self->_create_controls($sizer);

	# Bind the control events
	$self->_bind_events;

	# wrap everything in a vbox to add some padding
	$self->SetSizer($sizer);
	$self->Fit;
	$self->CentreOnParent;

	return $self;
}

#
# Create dialog controls
#
sub _create_controls {
	my ( $self, $sizer ) = @_;


	# Filter label
	my $filter_label = Wx::StaticText->new( $self, -1, '&Filter:' );

	# Filter text field
	$self->{filter} = Wx::TextCtrl->new( $self, -1, '' );

	# Filtered preferences list
	$self->{list} = Wx::ListView->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
	);
	$self->{list}->InsertColumn( 0, Wx::gettext('Preference Name') );
	$self->{list}->InsertColumn( 1, Wx::gettext('Status') );
	$self->{list}->InsertColumn( 2, Wx::gettext('Type') );
	$self->{list}->InsertColumn( 3, Wx::gettext('Value') );

	# Popup right-click menu
	$self->{popup}      = Wx::Menu->new;
	$self->{copy}       = $self->{popup}->Append( -1, Wx::gettext("Copy") );
	$self->{copy_name}  = $self->{popup}->Append( -1, Wx::gettext("Copy Name") );
	$self->{copy_value} = $self->{popup}->Append( -1, Wx::gettext("Copy Value") );

	# Preference value label
	my $value_label = Wx::StaticText->new( $self, -1, '&Value:' );

	# Preference value text field
	$self->{value} = Wx::TextCtrl->new( $self, -1, '' );
	$self->{value}->Enable(0);

	# System default
	my $default_label = Wx::StaticText->new( $self, -1, Wx::gettext('Default value:') );
	$self->{default_value} = Wx::TextCtrl->new(
		$self,
		-1,
		'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_READONLY
	);

	# Set preference value button
	$self->{button_set} = Wx::Button->new(
		$self, -1, Wx::gettext("&Set"),
	);
	$self->{button_set}->Enable(0);

	# Reset to default preference value button
	$self->{button_reset} = Wx::Button->new(
		$self, -1, Wx::gettext("&Reset"),
	);
	$self->{button_reset}->Enable(0);

	# Save button
	$self->{button_save} = Wx::Button->new(
		$self, Wx::wxID_OK, Wx::gettext("S&ave"),
	);
	$self->{button_save}->SetDefault;

	# Cancel button
	$self->{button_cancel} = Wx::Button->new(
		$self, Wx::wxID_CANCEL, Wx::gettext("&Cancel"),
	);

	#
	#----- Dialog Layout -------
	#

	# Top filter sizer
	my $filter_sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$filter_sizer->Add( $filter_label,   0, Wx::wxALIGN_CENTER_VERTICAL, 5 );
	$filter_sizer->Add( $self->{filter}, 1, Wx::wxALIGN_CENTER_VERTICAL, 5 );

	# Bottom preference value setter sizer
	my $value_sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$value_sizer->Add( $value_label,          0, Wx::wxALIGN_CENTER_VERTICAL, 5 );
	$value_sizer->Add( $self->{value},        1, Wx::wxALIGN_CENTER_VERTICAL, 5 );
	$value_sizer->Add( $self->{button_set},   0, Wx::wxALIGN_CENTER_VERTICAL, 5 );
	$value_sizer->Add( $self->{button_reset}, 0, Wx::wxALIGN_CENTER_VERTICAL, 5 );

	# Sizer for default value
	my $default_sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$default_sizer->Add( $default_label,         0, Wx::wxALIGN_CENTER_VERTICAL, 5 );
	$default_sizer->Add( $self->{default_value}, 1, Wx::wxALIGN_CENTER_VERTICAL, 5 );

	# button sizer
	my $button_sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$button_sizer->Add( $self->{button_save},   1, 0,          0 );
	$button_sizer->Add( $self->{button_cancel}, 1, Wx::wxLEFT, 5 );
	$button_sizer->AddSpacer(5);

	# Create the main vertical sizer
	my $vsizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$vsizer->Add( $filter_sizer,  0, Wx::wxALL | Wx::wxEXPAND, 3 );
	$vsizer->Add( $self->{list},  1, Wx::wxALL | Wx::wxEXPAND, 3 );
	$vsizer->Add( $value_sizer,   0, Wx::wxALL | Wx::wxEXPAND, 3 );
	$vsizer->Add( $default_sizer, 0, Wx::wxALL | Wx::wxEXPAND, 3 );
	$vsizer->AddSpacer(5);
	$vsizer->Add( $button_sizer, 0, Wx::wxALIGN_RIGHT, 5 );
	$vsizer->AddSpacer(5);

	# Wrap with a horizontal sizer to get left/right padding
	$sizer->Add( $vsizer, 1, Wx::wxALL | Wx::wxEXPAND, 5 );

	return;
}

#
# A Private method to binds events to controls
#
sub _bind_events {
	my $self = shift;

	# Set focus when Keypad Down or page down keys are pressed
	Wx::Event::EVT_CHAR(
		$self->{filter},
		sub {
			$self->_on_char( $_[1] );
		}
	);

	# Update filter search results on each text change
	Wx::Event::EVT_TEXT(
		$self,
		$self->{filter},
		sub {
			shift->_update_list;
		}
	);

	# When an item is selected, its values must be populated below
	Wx::Event::EVT_LIST_ITEM_SELECTED(
		$self,
		$self->{list},
		sub {
			shift->_on_list_item_selected(@_);
		}
	);

	# When an item is activated (e.g. double-clicked, space-ed or enter-ed)
	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{list},
		sub {
			shift->_on_list_item_activated(@_);
		}
	);

	# When an right click is pressed, let us show a popup menu
	Wx::Event::EVT_LIST_ITEM_RIGHT_CLICK(
		$self,
		$self->{list},
		sub {
			shift->_on_list_item_right_click(@_);
		}
	);

	# Copy everything to clipboard
	Wx::Event::EVT_MENU(
		$self,
		$self->{copy},
		sub {
			shift->_on_copy_to_clipboard( @_, "copy" );
		}
	);

	# Copy name to clipboard
	Wx::Event::EVT_MENU(
		$self,
		$self->{copy_name},
		sub {
			shift->_on_copy_to_clipboard( @_, "copy_name" );
		}
	);

	# Copy value to clipboard
	Wx::Event::EVT_MENU(
		$self,
		$self->{copy_value},
		sub {
			shift->_on_copy_to_clipboard( @_, "copy_value" );
		}
	);

	# Set button
	Wx::Event::EVT_BUTTON(
		$self,
		$self->{button_set},
		sub {
			shift->_on_set_button;
		}
	);

	# Reset button
	Wx::Event::EVT_BUTTON(
		$self,
		$self->{button_reset},
		sub {
			shift->_on_reset_button;
		}
	);

	# Save button
	Wx::Event::EVT_BUTTON(
		$self,
		$self->{button_save},
		sub {
			shift->_on_save_button;
		}
	);

	# Cancel button
	Wx::Event::EVT_BUTTON(
		$self,
		$self->{button_cancel},
		sub {
			shift->Hide;
		}
	);

	# Resize dialog event
	Wx::Event::EVT_SIZE(
		$self,
		sub {
			shift->_on_resize;
		}
	);
}

#
# Private method to copy preferences to clipboard
#
sub _on_copy_to_clipboard {
	my ( $self, $event, $obj ) = @_;

	my $list = $self->{list};
	my $name = $list->GetItemText( $list->GetFirstSelected );
	my $pref = $self->{preferences}{$name};

	my $text;
	if ( $obj eq "copy" ) {
		$text =
			  $name . ";"
			. ( $pref->{is_default} ? Wx::gettext('Default') : Wx::gettext('User set') ) . ";"
			. $pref->{type_name} . ";"
			. $pref->{value};
	} elsif ( $obj eq "copy_name" ) {
		$text = $name;
	} elsif ( $obj eq "copy_value" ) {
		$text = $pref->{value};
	}
	if ( $text and Wx::wxTheClipboard->Open() ) {
		Wx::wxTheClipboard->SetData( Wx::TextDataObject->new($text) );
		Wx::wxTheClipboard->Close();
	}

	return;
}

#
# Private method to show a popup menu when a list item is right-clicked
#
sub _on_list_item_right_click {
	my $self  = shift;
	my $event = shift;

	$self->{list}->PopupMenu(
		$self->{popup},
		$event->GetPoint->x,
		$event->GetPoint->y,
	);

	return;
}

#
# Private method to handle the dialog resize event
#
sub _on_resize {
	my $self = shift;

	$self->Layout;
	$self->_resize_columns;

	return;
}

#
# Private method to handle on character pressed event
#
sub _on_char {
	my $self  = shift;
	my $event = shift;
	my $code  = $event->GetKeyCode;

	$self->{list}->SetFocus
		if ( $code == Wx::WXK_DOWN )
		or ( $code == Wx::WXK_NUMPAD_PAGEDOWN )
		or ( $code == Wx::WXK_PAGEDOWN );

	$event->Skip(1);

	return;
}

#
# Private method to handle the selection of a preference item
#
sub _on_list_item_selected {
	my $self  = shift;
	my $event = shift;

	my $pref = $self->{preferences}{ $event->GetLabel };

	$self->{value}->SetValue( $pref->{value} );
	$self->{default_value}->SetLabel( $pref->{default} );

	$self->{value}->Enable(1);
	$self->{button_reset}->Enable( not $pref->{is_default} );
	$self->{button_set}->Enable(1);

	return;
}

sub _on_list_item_activated {
	my $self  = shift;
	my $event = shift;

	my $index = $event->GetIndex;
	my $list  = $self->{list};
	my $pref  = $self->{preferences}{ $event->GetLabel };

	if ( $pref->{type} == Padre::Constant::BOOLEAN ) {

		# Reverse boolean
		my $value = $pref->{value} ? 0 : 1;
		my $is_default = not $pref->{is_default};
		$pref->{is_default} = $is_default;
		$pref->{value}      = $value;

		# and update the fields/list items accordingly
		$self->_update_ui($pref);
	} else {

		# Focus on the text value so we can edit it...
		$self->{value}->SetFocus;
	}

	return;
}

#
# Private method to update the UI from the provided preference
#
sub _update_ui {
	my ( $self, $pref ) = @_;

	my $list       = $self->{list};
	my $index      = $list->GetFirstSelected;
	my $value      = $pref->{value};
	my $is_default = $pref->{is_default};

	$self->{value}->SetValue($value);
	$self->{default_value}->SetLabel( $pref->{default} );
	$self->{button_reset}->Enable( not $is_default );
	$list->SetItem( $index, 1, $is_default ? Wx::gettext('Default') : Wx::gettext('User set') );
	$list->SetItem( $index, 3, $value );
	$self->_set_item_bold_font( $index, not $is_default );

	return;
}


#
# Determines whether the preference value is default or not based on its type
#
sub _is_default {
	my ( $self, $type, $value, $default_value ) = @_;

	return ( $type == Padre::Constant::ASCII or $type == Padre::Constant::PATH )
		? $value eq $default_value
		: $value == $default_value;
}

#
# Private method to handle the pressing of the set value button
#
sub _on_set_button {
	my $self = shift;

	# Prepare the preferences
	my $list  = $self->{list};
	my $index = $list->GetFirstSelected;
	my $name  = $list->GetItemText($index);
	my $pref  = $self->{preferences}{$name};

	#TODO Implement some validation based on the preference type

	#Reset the value to the default setting
	my $type          = $pref->{type};
	my $value         = $self->{value}->GetValue;
	my $default_value = $pref->{default};
	my $is_default    = $self->_is_default( $type, $value, $default_value );

	$pref->{value}      = $value;
	$pref->{is_default} = $is_default;

	$self->_update_ui($pref);

	return;
}

#
# Private method to handle the pressing of the reset to default button
#
sub _on_reset_button {
	my $self = shift;

	# Prepare the preferences
	my $list  = $self->{list};
	my $index = $list->GetFirstSelected;
	my $name  = $list->GetItemText($index);
	my $pref  = $self->{preferences}{$name};

	#Reset the value to the default setting
	my $value = $pref->{default};
	$pref->{value}      = $pref->{default};
	$pref->{is_default} = 1;

	$self->_update_ui($pref);

	return;
}

#
# Private method to handle the pressing of the save button
#
sub _on_save_button {
	my $self = shift;

	#Save only changed stuff to config
	my $config = $self->main->config;
	my $prefs  = $self->{preferences};
	for my $name ( sort keys %$prefs ) {
		my $pref     = $prefs->{$name};
		my $type     = $pref->{type};
		my $value    = $pref->{value};
		my $original = $pref->{original};
		my $changed =
			( $type == Padre::Constant::ASCII or $type == Padre::Constant::PATH )
			? $value ne $original
			: $value != $original;

		if ($changed) {
			$config->set( $name, $value );
		}
	}

	# And commit configuration...
	$config->write;

	# Bye bye dialog
	$self->Hide;

	return;
}


#
# Private method to update the preferences list
#
sub _update_list {
	my $self = shift;

	my $config = $self->main->config;

	my $filter = $self->{filter}->GetValue;

	#quote the search string for safety
	$filter = quotemeta $filter;

	my $list = $self->{list};
	$list->DeleteAllItems;
	my $index          = -1;
	my $preferences    = $self->{preferences};
	my $alternateColor = Wx::Colour->new( 0xED, 0xF5, 0xFF );
	for my $name ( sort keys %$preferences ) {

		# Ignore setting if it does not match the filter
		next if $name !~ /$filter/i;

		# Add the setting to the list control
		my $setting    = $preferences->{$name};
		my $is_default = $setting->{is_default};

		$list->InsertStringItem( ++$index, $name );
		$list->SetItem( $index, 1, $is_default ? Wx::gettext('Default') : Wx::gettext('User set') );
		$list->SetItem( $index, 2, $setting->{type_name} );
		$list->SetItem( $index, 3, $setting->{value} );

		# Alternating table colors
		$list->SetItemBackgroundColour( $index, $alternateColor ) unless $index % 2;

		# User-set or non-default preferences have bold font
		$self->_set_item_bold_font( $index, not $is_default );
	}

	return;
}

#
# Private method to set item to bold
# Somehow SetItemFont is not there... hence i had to write this long workaround
#
sub _set_item_bold_font {
	my ( $self, $index, $bold ) = @_;

	my $list = $self->{list};
	my $item = $list->GetItem($index);
	my $font = $item->GetFont;
	$font->SetWeight( $bold ? Wx::wxFONTWEIGHT_BOLD : Wx::wxFONTWEIGHT_NORMAL );
	$item->SetFont($font);
	$list->SetItem($item);

	return;
}

#
# Private method to initialize a preferences hash from the local configuration
#
sub _init_preferences {
	my $self = shift;

	my %settings = %Padre::Config::SETTING;
	my $config   = $self->main->config;
	my %types    = (
		Padre::Constant::BOOLEAN => Wx::gettext("Boolean"),
		Padre::Constant::POSINT  => Wx::gettext("Positive integer"),
		Padre::Constant::INTEGER => Wx::gettext("Integer"),
		Padre::Constant::ASCII   => Wx::gettext("ASCII"),
		Padre::Constant::PATH    => Wx::gettext("Path"),
	);

	$self->{preferences} = ();
	for my $name ( sort keys %settings ) {
		my $setting = $settings{$name};

		my $type      = $setting->type;
		my $type_name = $types{$type};
		unless ($type_name) {
			warn "Unknown type: $type while reading $name\n";
			next;
		}

		my $value         = $config->$name;
		my $default_value = $setting->default;
		my $is_default    = $self->_is_default( $type, $value, $default_value );

		$self->{preferences}{$name} = {
			'is_default' => $is_default,
			'default'    => $default_value,
			'type'       => $type,
			'type_name'  => $type_name,
			'value'      => $value,
			'original'   => $value,
		};
	}

	return;
}

#
# Private method to resize list columns
#
sub _resize_columns {
	my $self = shift;

	# Resize all columns but the last to their biggest item width
	my $list               = $self->{list};
	my $total_column_width = 0;
	for ( 0 .. 2 ) {
		$list->SetColumnWidth( $_, Wx::wxLIST_AUTOSIZE );
		$total_column_width += $list->GetColumnWidth($_);
	}

	# The second column (status) can be bold
	$list->SetColumnWidth( 1, $list->GetColumnWidth(1) + 10 );

	# the last column gets the remaining list width
	$list->SetColumnWidth( 3, $list->GetSize->GetWidth - $total_column_width - 21 );
}

=pod

=head2 C<show>

  $advanced->show($main);

Shows the dialog. Returns C<undef>.

=cut

sub show {
	my $self = shift;

	# Initialize Preferences
	$self->_init_preferences;

	# Set focus on the filter text field
	$self->{filter}->SetFocus;

	# Update the preferences list
	$self->_update_list;

	# resize columns
	$self->_resize_columns;

	# If it is not shown, show the dialog
	$self->ShowModal;

	return;
}

1;

=pod

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
