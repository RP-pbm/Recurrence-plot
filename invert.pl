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
my $pbm = 0;
my $pgm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $max_val;

for( @opt ){
	/-max(?:val)?(\d+)/ and do {
		$max_val = $1;
	};
	/-pbm/ and do {
		$pbm = 1;
	};
	/-pgm/ and do {
		$pgm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
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
}

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = grep m/./, ( defined $in ? <$in> : <STDIN> );
	chomp @data;
	
	if( $to_pbm and $pgm or $to_pgm and $pbm ){
		die "error: Attempt to convert between formats!\n";
		}
	
	my( $rows, $cols );
	
	if( $pbm or $pgm ){
		shift @data;
		( $rows, $cols ) = reverse split ' ', shift @data;
		if( $pgm ){
			$max_val = shift @data;
			}
		else{
			$max_val = 1;
			}
		}
	
	if( $to_pbm || $to_pgm and ! $pbm and ! $pgm ){
		( $rows, $cols ) = ( ~~ @data, ~~ split $split, $data[0] );
		}
	
	if( not defined $max_val ){
		$max_val = ( sort { $b <=> $a } map { split $split } @data )[ 0 ];
		}
	
	if( $to_pbm ){
		print "P1\n";
		print "$cols $rows\n";
	}
	
	if( $to_pgm ){
		print "P2\n";
		print "$cols $rows\n";
		print $max_val . "\n";
	}
	
	print map "$_\n", join $join, map { $max_val - $_ } split $split for @data;
}
