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
my $starting_pos = 0;
my $length;
my $tau = 1;
my $m = 3;
my $log_base = 2;
my $normalize = 0;

for( @opt ){
	/-starting-pos(\d+)/ and do {
		$starting_pos = $1;
	};
	/-length(\d+)/ and do {
		$length = $1;
	};
	/-tau(\d+)/ and do {
		$tau = $1;
	};
	/-m(\d+)/ and do {
		$m = $1;
	};
	/-log-base(\d+)/ and do {
		$log_base = $1;
	};
	/-normalize/ and do {
		$normalize = 1;
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
	
	if( not defined $length ){
		$length = @{ $data[ 0 ] };
		}
	
	@{ $_ } = @{ $_ }[ $starting_pos .. $starting_pos + $length - 1 ] for @data;
	
	my $i = 0;
	$i = 0, @{ $_ } = map { [ $_, $i ++ ] } @{ $_ } for @data;
	
	my %hash_of_permutations;
	
	for my $ref_line ( @data ){
		for my $i ( 0 .. @{ $ref_line } - ( $m - 1 ) * $tau - 1 ){
			my @X_refs = @{ $ref_line }[ map { $i + $_ * $tau } 0 .. $m - 1 ];
			$debug and print map "$_\n", join '|', map { join ' ', @{ $_ } } @X_refs;
			
			my @pi = map $_->[ 1 ], sort { $a->[ 0 ] <=> $b->[ 0 ] } @X_refs;
			$debug and print "\@pi:[@pi]\n";
			
			map { ( $_ -= $i ) /= $tau } @pi;
			$debug and print "\@pi:[@pi]\n";
			
			$hash_of_permutations{ "@pi" } ++;
			}
		
		my $sum = 0;
		
		for my $key ( keys %hash_of_permutations ){
			my $p = $hash_of_permutations{ $key } / ( @{ $ref_line } - ( $m - 1 ) * $tau );
			my $value = - $p * log_base( $p, $log_base );
			$debug and print "value:$value\n";
			
			$sum += $value;
			}
		
		if( $normalize ){
			$sum /= log_base( ( eval join '*', 1 .. $m ), 2 );
			};
		
		print "sum:$sum\n";
		}
}

sub log_base {
	my( $n, $base ) = @_;
	return log( $n ) / log( $base );
    }