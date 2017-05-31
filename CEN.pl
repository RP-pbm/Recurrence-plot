#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for (@ARGV){
	/^-\S/ ? (push @opt, $_) : (push @FILES, $_);
}

my $split = " ";
my $join = " ";
my $pbm = 0;
my $to_pbm = 0;
my $whole_CEN = 0;
my $power = 2;
my $print_RRc = 0;
my $print_ratios = 0;

for (@opt){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-power(\d+)/ and do {
		$power = $1;
	};
	/-whole/ and do {
		$whole_CEN = 1;
	};
	/-rrc/i and do {
		$print_RRc = 1;
	};
	/-ratios/ and do {
		$print_ratios = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
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

for (@FILES){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = grep m/./, (defined $in ? <$in> : <STDIN>);
	chomp @data;
	
	my( $rows, $cols );
	if( $pbm ){
		shift @data;
		( $rows, $cols ) = reverse split ' ', shift @data;
	}
	else{
		( $rows, $cols ) = ( 0 + @data, 0 + split $split, $data[0] );
	}

	@data = map { [ split $split ] } @data;
	
	if( ! $whole_CEN ){
	
		my @CEN;
		my @RRc;
		my @ratios;
		
		for my $col ( 0 .. $cols - 1 ){
			
			my $sum = 0;
			my $RRc = 0;
			
			for my $row ( 0 .. $rows - 1 ){
				
				next if not $data[ $row ][ $col ];
				$RRc ++;
				
				$sum += abs( $row - $col ) ** $power;
				
				}
			
			my $CEN = sprintf "%.4f", $RRc > 1 ? 
				$RRc / $rows / ( $sum / ( $RRc - 1 ) ) ** (1 / $power) : 0;
			
			push @CEN, $CEN;
			push @RRc, $RRc;
			push @ratios, $RRc ? $CEN / $RRc : 0;
			}
		
		
		print do { local $" = $join; "@CEN\n" }; 
		if( $print_RRc ){
			print do { local $" = $join; "@RRc\n" }; 
			}
		if( $print_ratios ){
			print do { local $" = $join; "@ratios\n" }; 
			}
	
	} else { 
		
		my $RR = map { grep $_, @{$_} } @data;
		$debug and print "RR: ", $RR, "\n";
		
		my $sum_sum = 0;
		
		for my $col ( 0 .. $cols - 1 ){
			
			my $sum = 0;
			my $RRc = 0;
			
			for my $row ( 0 .. $rows - 1 ){
				
				next if not $data[ $row ][ $col ];
				
				$RRc ++;
				$sum += abs( $row - $col ) ** $power;
				
				}
			
			$sum_sum += $RRc > 1 ? $sum : 0; 
			
			}
		$debug and print "sum_sum: $sum_sum\n";
		
		my $CEN = sprintf "%.5f", $RR > 1 && $sum_sum ? 
			$RR / $rows / $cols / ( $sum_sum / ( $RR - 1 ) ) ** (1 / $power) : 0;
		
		print $CEN, "\n";
	}
	
}
