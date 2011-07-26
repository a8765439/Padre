package Padre::DB::Migrate::Patch5;

use 5.008;
use strict;
use warnings;
use Padre::DB::Migrate::Patch ();

our $VERSION = '0.85';
our @ISA     = 'Padre::DB::Migrate::Patch';





######################################################################
# Migrate Forwards

sub upgrade {
	my $self = shift;

	# Create the session table
	$self->do(<<'END_SQL');
CREATE TABLE session (
	id INTEGER NOT NULL PRIMARY KEY,
	file VARCHAR(255) UNIQUE NOT NULL,
	line INTEGER NOT NULL,
	character INTEGER NOT NULL,
	clue VARCHAR(255),
	focus BOOLEAN NOT NULL
)
END_SQL

	return 1;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
