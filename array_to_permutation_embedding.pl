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
my $length;
my $m = 3;

for( @opt ){
	/-m(\d+)/ and do {
		$m = $1;
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

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	
	my @data = map { chomp; [ split $split ] } grep m/./, ( defined $in ? <$in> : <STDIN> );
	
	$debug and print "@{ $_ }\n" for @data;
	
	my $length = @{ $data[ 0 ] };
	
	my $i = 0;
	$i = 0, @{ $_ } = map { [ $_, $i ++ ] } @{ $_ } for @data;
	
	my @result;
	push @result, [] for 1 .. $m;

	for my $ref_line ( @data ){
		for my $i ( 0 .. @{ $ref_line } - $m - 0 ){
			my @X_refs = @{ $ref_line }[ map { $i + $_ } 0 .. $m - 1 ];
			$debug and print map "$_\n", join '|', map { join ' ', @{ $_ } } @X_refs;
			
			my @pi = map $_->[ 1 ], sort { $a->[ 0 ] <=> $b->[ 0 ] } @X_refs;
			$debug and print "\@pi:[@pi]\n";
			
			map { $_ -= $i } @pi;
			$debug and print "\@pi:[@pi]\n";
			
			for my $j ( 0 .. @pi - 1 ){
				push @{ $result[ $j ] }, $pi[ $j ];
				}
			}
		
		print map "$_\n", join $join, @{ $_ } for @result;
		}
}

