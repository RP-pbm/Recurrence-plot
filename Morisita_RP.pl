#!/usr/bin/perl

use strict;
use warnings;

my $debug = 0;

my @FILES;
my @opt;

for (@ARGV){
	/^-\S/ ? (push @opt, $_) : (push @FILES, $_);
}

my $split = " ";
my $join = " ";
my $Simpson = 0;

for (@opt){
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

for (@FILES){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: can't open $_\n";
	my @data = map { chomp; [ split /$split/ ] } 
		grep m/./, (defined $in ? <$in> : <STDIN>);
	
	my( $cols, $rows ) = ( ~~ @{ $data[0] }, ~~ @data );
	
	$debug and print "cols: $cols, rows: $rows\n";
	$debug and print "@{$_}\n" for @data;

	my @Xi;

	for my $i (1 .. $cols){
		my $sum;
		for my $j (1 .. $rows){
		    $sum += $data[ $j-1 ][ $i-1 ];
			$debug and print "  $i $j: $sum";
		}
		push @Xi, $sum;
	}

	my @lambda_i;

	for my $i (1 .. $cols){
		my $sum = 0;
		for my $j (1 .. $rows){
			( $Xi[ $i-1 ] * ( $Xi[ $i-1 ] - $Simpson ) ) or next;
		    $sum += ( $data[ $j-1 ][ $i-1 ] * 
					( $data[ $j-1 ][ $i-1 ] - $Simpson ) ) /
					( $Xi[ $i-1 ] * ( $Xi[ $i-1 ] - $Simpson ) );
		}
		$debug and printf "    lambda_i [%d]: %s\n", $i, $sum;
		push @lambda_i, $sum;
	}

	$debug and print "\@lambda_i: @lambda_i\n";

	my @matrix;

	for my $i (1 .. $cols){
		my @line;
		for my $j (1 .. $cols){
		    my $sum;
		    for my $r (@data){
		        $sum += $r->[ $i-1 ] * $r->[ $j-1 ];
		    }
		    push @line, 
				$Xi[ $i-1 ] == 0 || $Xi[ $j-1 ] == 0 ?
					0
				:
					2 * $sum 
					/ ( ($lambda_i[ $i-1 ] + $lambda_i[ $j-1 ]) 
						* $Xi[ $i-1 ] * $Xi[ $j-1 ] );
		}
		push @matrix, [ @line ];
	}

	print map "$_\n", join "$join", @{$_} for @matrix;

}

