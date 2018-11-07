#!/usr/bin/perl

use strict;
use warnings;

my $debug = 0;

my @FILES;
my @opt;

for( @ARGV ){
	/^-\S/ ? ( push @opt, $_ ) : ( push @FILES, $_ );
}

my $split = " ";
my $join = " ";
my $pbm = 0;
my $topbm = 0;
my $intersection = 1;  # a.k.a. multiplication
my $union = 0;
my $difference = 0;

for( @opt ){
	/-mult\w*|-intersection/ and do {
		$intersection = 1;
	};
	/-union/ and do {
		$union = 1;
		$intersection = 0;
	};
	/-diff\w*/ and do {
		$difference = 1;
		$intersection = 0;
	};
	/-pbm/ and do {
		$pbm = 1;
	};
	/-topbm/ and do {
		$topbm = 1;
	};
	/-tsv/ and do {
		$split = "\t";
	};
	/-csv/ and do {
		$split = ',';
	};
	/-cssv/ and do {
		$split = ', ';
	};
	/-ssv/ and do {
		$split = ' ';
	};
	/-nosep/ and do {
		$split = '';
	};
	/-totsv/ and do {
		$join = "\t";
	};
	/-tocsv/ and do {
		$join = ',';
	};
	/-tocssv/ and do {
		$join = ', ';
	};
	/-tossv/ and do {
		$join = ' ';
	};
	/-tonosep/ and do {
		$join = '';
	};
	/-d$/ and $debug = 1;
}

if( @FILES != 2 ){
	die "\@FILES != 2; There must be two data files to compare.\n";
	}
	
	$debug and print "<<@FILES>>\n";
	
	open my $in0, '<', $FILES[0] or die "$0: Can't open '$FILES[0]' : $!\n";
	open my $in1, '<', $FILES[1] or die "$0: Can't open '$FILES[1]' : $!\n";
	my @data;
	push @data, [ map { chomp; $_ } grep m/./, <$_> ] for $in0, $in1;
	
	my @cols;
	my @rows;
	
	# discard pbm header
	if( $pbm ){
		for my $u ( 0 .. 1 ){
			shift @{ $data[$u] };
			shift @{ $data[$u] };
			}
		}
	
	for my $u ( 0 .. 1 ){
		@{ $data[$u] } = map { [ split $split ] } @{ $data[$u] };
		$debug and print "@{$_}\n" for @{ $data[$u] };
		}
	
	for my $u ( 0 .. 1 ){
		( $cols[$u], $rows[$u] ) = ( ~~ @{ $data[$u][0] }, ~~ @{ $data[$u] } );
		$debug and print "[( $cols[$u], $rows[$u] )]\n";
		}
		
	if( $rows[0] != $rows[1] ){
		die "Number of rows must be equal!\n";
		}
	
	if( $cols[0] != $cols[1] ){
		die "Number of columns must be equal!\n";
		}
	
	if( $intersection ){
		for my $i ( 1 .. $rows[0] ){
			for my $j ( 1 .. $cols[0] ){
				$data[2][ $i-1 ][ $j-1 ] = 
				$data[0][ $i-1 ][ $j-1 ] * 
				$data[1][ $i-1 ][ $j-1 ];
				}
			}
		}
	
	if( $union ){
		for my $i ( 1 .. $rows[0] ){
			for my $j ( 1 .. $cols[0] ){
				$data[2][ $i-1 ][ $j-1 ] = 
				$data[0][ $i-1 ][ $j-1 ] | 
				$data[1][ $i-1 ][ $j-1 ];
				}
			}
		}
	
	if( $difference ){
		for my $i ( 1 .. $rows[0] ){
			for my $j ( 1 .. $cols[0] ){
				$data[2][ $i-1 ][ $j-1 ] = 
				$data[0][ $i-1 ][ $j-1 ] - 
				$data[1][ $i-1 ][ $j-1 ];
				$data[2][ $i-1 ][ $j-1 ] =~ s/^-\d+$/0/;
				}
			}
		}
	
	if( $topbm ){
		print "P1\n";
		print "$cols[0] $rows[0]\n";
		}
	
	print map "$_\n", join $join, @{$_} for @{ $data[2] };

