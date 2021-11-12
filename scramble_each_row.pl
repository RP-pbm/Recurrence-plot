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

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = map { chomp; [ split $split ] } grep m/./, 
		( defined $in ? <$in> : <STDIN> );
	
	for my $row ( @data ){
		
		$debug and print "[@{$row}]\n";
		
		my $cnt_zeroes = 0;
		my $cnt_leading_zeroes = 0;
		my $cnt_trailing_zeroes = 0;
		
		for my $i ( 0 .. @{$row} - 1 ){
			$row->[ $i ] == 0 and $cnt_zeroes ++;
			}
		
		for my $i ( 0 .. @{$row} - 1 ){
			$row->[ $i ] == 0 and $cnt_leading_zeroes ++;
			$row->[ $i ] != 0 and last;
			}
		
		for my $i ( reverse 0 .. @{$row} - 1 ){
			$row->[ $i ] == 0 and $cnt_trailing_zeroes ++;
			$row->[ $i ] != 0 and last;
			}
		
		$debug and print 
			"All zeroes ($cnt_zeroes) ?? " .
			"leading zeroes ($cnt_leading_zeroes) + " . 
			"trailing zeroes ($cnt_trailing_zeroes)!\n";
		
		if( $cnt_zeroes != $cnt_leading_zeroes + $cnt_trailing_zeroes ){
			die "All zeroes ($cnt_zeroes) != " .
				"leading zeroes ($cnt_leading_zeroes) + " . 
				"trailing zeroes ($cnt_trailing_zeroes)!\n";
			}
		
		my $start_pos;
		
		for my $i ( 0 .. @{$row} - 1 ){
			$row->[ $i ] != 0 and do {
				$start_pos = $i;
				last;
				};
			}
		
		my @new = @{$row}[ $start_pos .. $start_pos + @{$row} - $cnt_zeroes - 1 ];
		
		my $rand = int rand 1 + $cnt_zeroes;
		
		unshift @new, ( 0 ) x $rand;
		push @new, ( 0 ) x ( $cnt_zeroes - $rand );
		
		print map "$_\n", join $join, @new;
		}

}
