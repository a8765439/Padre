package Padre::Util::Win32;

=pod

=head1 NAME

Padre::Util::Win32 - Padre Win32 Utility Functions

=head1 DESCRIPTION

The Padre::Util::Win32 package is a internal storage area for miscellaneous
functions that aren't really Padre-specific that we want to throw
somewhere convenient so they won't clog up task-specific packages.

All functions are exportable and documented for maintenance purposes,
but except for in the L<Padre> core distribution you are discouraged in the
strongest possible terms from using these functions, as they may be
moved, removed or changed at any time without notice.

=head1 FUNCTIONS

=cut

use 5.008;
use strict;
use warnings;

use Padre::Constant ();

# This module may be loaded by others, so don't crash on Linux when just being loaded:
require Win32::API if Padre::Constant::WIN32;

our $VERSION   = '0.46';

#
# Converts the specified path to its long form.
#
# Needs a path string
# Returns undef for failure, or the long form of the specified path
#
sub GetLongPathName {

	# Only for win32
	die "Win32 function called!" unless Padre::Constant::WIN32;

	my $path = shift;

	# Allocate a buffer that can take the maximum allowed win32 path
	my $MAX_PATH = 260 + 1;
	my $buf      = ' ' x $MAX_PATH;

	my $func = Win32::API->new( kernel32 => <<'CODE');
	DWORD GetLongPathName( 
		LPCTSTR lpszShortPath,
		LPTSTR lpszLongPath,
		DWORD cchBuffer
	);
CODE
	my $length = $func->Call( $path, $buf, $MAX_PATH );

	return $length ? substr( $buf, 0, $length ) : undef;
}

#
# Move to recycle bin
#
# Returns undef (failed), zero (aborted) or one (success)
#
sub Recycle {

	# Only for win32
	die "Win32 function called!" unless Padre::Constant::WIN32;

	my $file_to_recycle = shift;

	# define the win32 structure
	Win32::API::Struct->typedef(
		SHFILEOPSTRUCT => qw(
			HWND hwnd;
			UINT wFunc;
			LPCTSTR pFrom;
			LPCTSTR pTo;
			FILEOP_FLAGS fFlags;
			BOOL fAnyOperationsAborted;
			LPVOID hNameMappings;
			LPCTSTR lpszProgressTitle;
			)
	);

	# prepare structure for win32 call
	my $op = Win32::API::Struct->new('SHFILEOPSTRUCT');
	$op->{wFunc}  = 0x0003;                   # FO_DELETE from ShellAPI.h
	$op->{fFlags} = 0x0040;                   # FOF_ALLOWUNDO from ShellAPI.h
	$op->{pFrom}  = $file_to_recycle . "\0\0";

	# perform the recycling
	my $result = Win32::API->new( shell32 => q{ int SHFileOperation( LPSHFILEOPSTRUCT lpFileOp ) } )->Call($op);

	# failed miserably
	return undef if $result;

	# user aborted...
	return 0 if $op->{fAnyOperationsAborted};

	# file recycled
	return 1;
}

#
# Enables the specified process to set the foreground window
# via SetForegroundWindow
#
sub AllowSetForegroundWindow {

	die "Win32 function called!" unless Padre::Constant::WIN32;

	my ( $self, $pid ) = @_;

	my $func = Win32::API->new( shell32 => <<'CODE');
BOOL AllowSetForegroundWindow(      
    DWORD dwProcessId
);
CODE
	return $func->Call($pid);
}

#
# Execute a background process and wait for it to end
# If you set Show to 0, then you have an invisible command line window on win32!
#
sub ExecuteProcessAndWait {

	die "Win32 function called!" unless Padre::Constant::WIN32;

	my ( $App_Name, $Cmd_Line, $Show ) = @_;

	Win32::API::Struct->typedef(
		'SHELLEXECUTEINFO', qw(
			DWORD cbSize;
			ULONG fMask;
			HWND hwnd;
			LPCTSTR lpVerb;
			LPCTSTR lpFile;
			LPCTSTR lpParameters;
			LPCTSTR lpDirectory;
			int nShow;
			HINSTANCE hInstApp;
			LPVOID lpIDList;
			LPCTSTR lpClass;
			HKEY hkeyClass;
			DWORD dwHotKey;
			HANDLE hIconOrMonitor;
			HANDLE hProcess;
			)
	);

	my $info = Win32::API::Struct->new('SHELLEXECUTEINFO');
	$info->{cbSize}       = $info->sizeof;
	$info->{lpVerb}       = 'open';
	$info->{lpFile}       = $App_Name;
	$info->{lpParameters} = $Cmd_Line;
	$info->{nShow}        = $Show;
	$info->{fMask}        = 0x40;         #SEE_MASK_NOCLOSEPROCESS
	my $ShellExecuteEx = Win32::API->new( shell32 => <<'CODE');
		BOOL ShellExecuteEx(
		    LPSHELLEXECUTEINFO lpExecInfo
		);
CODE

	if ( $ShellExecuteEx->Call($info) ) {

		# Wait for the process to finish
		my $WaitForSingleObject = Win32::API->new( kernel32 => <<'CODE');
			DWORD WaitForSingleObject(
			    HANDLE hHandle,
			    DWORD dwMilliseconds
			);
CODE
		$WaitForSingleObject->Call( $info->{hProcess}, 0xFFFFFFFF );

		# Clean process handle!
		my $CloseHandle = Win32::API->new( kernel32 => <<'CODE');
			BOOL CloseHandle(
			    HANDLE hObject
			);
CODE
		$CloseHandle->Call( $info->{hProcess} );

		# And we have finished successfully
		return 1;
	}

	# We failed miserably!
	return 0;
}

1;

__END__

=pod

=head1 COPYRIGHT

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
