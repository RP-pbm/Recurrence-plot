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
my $pbm = 0;
my $pgm = 0;
my $ppm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $to_ppm = 0;
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
	/-ppm/ and do {
		$ppm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
	};
	/-toppm/ and do {
		$to_ppm = 1;
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
}

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = grep m/./, ( defined $in ? <$in> : <STDIN> );
	chomp @data;
	
	if( $to_pbm and $pgm || $ppm or $to_pgm and $pbm || $ppm or $to_ppm and $pbm || $pgm ){
		die "error: Attempt to convert between formats!\n";
		}
	
	my( $rows, $cols );
	
	if( $pbm || $pgm || $ppm ){
		shift @data;
		( $rows, $cols ) = reverse split ' ', shift @data;
		if( $pgm || $ppm ){
			$max_val = shift @data;
			}
		}
	
	if( !$pbm && !$pgm && !$ppm ){
		( $rows, $cols ) = ( ~~ @data, ~~ split $split, $data[0] );
		}
	
	if( $to_pbm ){
		print "P1\n";
		print "$cols $rows\n";
	}
	
	if( $to_pgm || $to_ppm and not defined $max_val ){
		$max_val = ( sort { $b <=> $a } map { split $split } @data )[ 0 ];
		}
	
	if( $to_pgm ){
		print "P2\n";
		print "$cols $rows\n";
		print $max_val . "\n";
	}
	
	if( $to_ppm ){
		print "P3\n";
		print "$cols $rows\n";
		print $max_val . "\n";
	}
	
	print "$_\n" for reverse @data;
}
