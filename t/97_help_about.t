#!/usr/bin/perl

use strict;
use warnings;
# Turn on $OUTPUT_AUTOFLUSH 
$|  = 1;
use Test::More;

BEGIN {
	unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
	plan tests => 13;
}

use Test::NoWarnings;
use t::lib::Padre;
use Padre::Wx;
use Padre;
use_ok('Padre::Wx::Dialog::About');

# Create the IDE
my $padre = new_ok('Padre');
my $main  = $padre->wx->main;
isa_ok( $main, 'Padre::Wx::Main' );

# Create the patch dialog
my $dialog = new_ok( 'Padre::Wx::Dialog::About', [$main] );

# Check the notebook properties
my $notebook = $dialog->notebook;
isa_ok( $notebook, 'Wx::Notebook' );

# Check the output properties
my $output = $dialog->output;
isa_ok( $output, 'Wx::TextCtrl' );

######
# let's check our subs/methods.
######
my @subs = qw( core_info new run set_up wx_info );

use_ok( 'Padre::Wx::Dialog::About', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Wx::Dialog::About', $subs );
}
