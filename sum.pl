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
my $rows = 1;
my $cols = 0;
my $whole = 0;

for( @opt ){
	/-rows/ and do {
		$rows = 1;
		$cols = 0;
	};
	/-cols/ and do {
		$rows = 0;
		$cols = 1;
	};
	/-whole/ and do {
		$whole = 1;
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

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = map { chomp; [ split $split ] } grep m/./, 
		( defined $in ? <$in> : <STDIN> );
	
	my @sum;
	
	for my $row ( @data ){
	
		if( $rows ){
			my $sum = 0;
			$sum += $_ for @{ $row };
			push @sum, $sum;
			}
		elsif( $cols ){
			for my $i ( 0 .. @{ $row } - 1 ){
				$sum[ $i ] += $row->[ $i ];
				}
			}
		}
	
	if( $whole ){
		my $sum = 0;
		$sum += $_ for @sum;
		@sum = $sum;
		}
	
	print map "$_\n", join $join, @sum;
}
