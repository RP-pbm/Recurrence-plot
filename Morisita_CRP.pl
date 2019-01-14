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
my $Simpson = 0;

for( @opt ){
	/-simpson/i and do {
		$Simpson = 1;
	};
	/-F(\S+)/ and do {
		$split = $1;
	};
	/-toF(\S+)/ and do {
		$join = $1;
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
	/-d$/ and $debug = 1;
}

if( @FILES != 2 ){
	die "\@FILES != 2; There must be two data files to compare.\n";
	}
	
	$debug and print "\@FILES: @FILES\n";
	
	open my $in0, '<', $FILES[0] or die "$0: can't open $FILES[0]\n";
	open my $in1, '<', $FILES[1] or die "$0: can't open $FILES[1]\n";
	my @data;
	push @data, [ map { chomp; [ split $split ] } 
		grep m/./, <$_> ] for $in0, $in1;
		
	my @cols;
	my @rows;
	
	for my $file ( 0 .. 1 ){
		( $cols[$file], $rows[$file] ) = 
			( ~~ @{ $data[$file][0] }, ~~ @{ $data[$file] } );
		$debug and print "cols: $cols[$file], rows: $rows[$file]\n";
	}
	
	if( $rows[0] != $rows[1] ){
		die "Number of rows (dimensions) must be equal!\n";
		}
	
	my $rows = $rows[0];
	
	for my $file ( 0 .. 1 ){
		$debug and print "@{$_}\n" for @{ $data[$file] };
	}
	
	my @Xi;
	
	for my $file ( 0 .. 1 ){
		for my $i ( 1 .. $cols[$file] ){
			my $sum;
			for my $j ( 1 .. $rows ){
				$sum += $data[$file][ $j-1 ][ $i-1 ];
				$debug and print "  $i $j: $sum";
			}
			push @{ $Xi[$file] }, $sum;
		}
	}

	my @lambda_i;
	
	for my $file ( 0 .. 1 ){
		for my $i ( 1 .. $cols[$file] ){
			my $sum = 0;
			for my $j ( 1 .. $rows ){
				( $Xi[$file][ $i-1 ] * ( $Xi[$file][ $i-1 ] - $Simpson ) ) or next;
				$sum += ( $data[$file][ $j-1 ][ $i-1 ] * 
						( $data[$file][ $j-1 ][ $i-1 ] - $Simpson ) ) /
					( $Xi[$file][ $i-1 ] * ( $Xi[$file][ $i-1 ] - $Simpson ) );
			}
			$debug and printf "    lambda_i_${file} [%d]: %s\n", $i, $sum;
			push @{ $lambda_i[$file] }, $sum;
		}
	}
	
	$debug and print "\@lambda_i_${_}: @{ $lambda_i[$_] }\n" for 0 .. 1;

	my @matrix;

	for my $i ( 1 .. $cols[0] ){
		my @line;
		for my $j ( 1 .. $cols[1] ){
			my $sum;
			for my $r ( 0 .. $rows - 1 ){
				$sum += $data[0][$r][ $i-1 ] * $data[1][$r][ $j-1 ];
				$debug and print 
					"[$i:$data[0][$r][ $i-1 ] * $j:$data[1][$r][ $j-1 ]]\n";
			}
			push @line, 
				$Xi[0][ $i-1 ] == 0 || $Xi[1][ $j-1 ] == 0 ?
					0
				:
					2 * $sum / 
					( ( $lambda_i[0][ $i-1 ] + $lambda_i[1][ $j-1 ] ) 
						* $Xi[0][ $i-1 ] * $Xi[1][ $j-1 ] );
		}
		push @matrix, [ @line ];
	}

	print map "$_\n", join $join, @{$_} for @matrix;

