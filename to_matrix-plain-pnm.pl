#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for( @ARGV ){
	/^-\S/ ? ( push @opt, $_ ) : ( push @FILES, $_ );
}

my $split = " ";
my $join = " ";

for( @opt ){
	/-ssv/ and do {
		$split = ' ';
	};
	/-nosep/ and do {
		$split = '';
	};
	/-d$/ and $debug = 1;
}

if( @FILES != 1 ){
	die "$0: Only one file can be processed at once. $!\n";
	}

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = grep m/./, ( defined $in ? <$in> : <STDIN> );
	chomp @data;
	
	my $header = shift @data;
	my( $cols, $rows ) = split ' ', shift @data;
	
	my $maxval;
	
	if( $header =~ /^P[23]$/ ){
		$maxval = shift @data;
		}
	elsif( $header eq 'P1' ){
		$split = '';
		}
	else{
		die "$0: Not a plain PBM/PGM/PPM. $!\n";
		}
	
	my $cols_P = $cols;
	
	if( $header eq 'P3' ){
		$cols_P *= 3;
		}
	
	my @all_values = split $split, join $split, @data;
	
	if( @all_values != $cols_P * $rows ){
		die "$0: Number of values != cols * rows, (if P3: * 3). $!\n";
		}
	
	print "$header\n";
	print "$cols $rows\n";
	print "$maxval\n" if defined $maxval;
	
	while( @all_values ){
		my @line = splice @all_values, 0, $cols_P, ();
		my $line = join $join, @line;
		print "$line\n";
		}
}
