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
my $T = 7;
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
	/-T(\d+)/ and do {
		$T = $1;
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

my $c_permutations = $T - $m + 1;

my %nxlogn;

%nxlogn = map { $_ => - $_ / $c_permutations * log_base( $_ / $c_permutations, $log_base ); } 
	1 .. $c_permutations;

$debug and print "[$_ => $nxlogn{ $_ }]\n" for 1 .. $c_permutations;


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
	
	for my $ref_series ( @data ){
		
		my @array_of_permutations;
		
		for my $i ( 0 .. @{ $ref_series } - $m ){
			$debug and print "i:$i\n";
			
			my @X_refs = @{ $ref_series }[ map { $i + $_ } 0 .. $m - 1 ];
			$debug and print map "$_\n", join ' | ', map { join ' ', @{ $_ } } @X_refs;
			
			my @pi = map $_->[ 1 ], sort { $a->[ 0 ] <=> $b->[ 0 ] } @X_refs;
			$debug and print "\@pi:[@pi]\n";
			
			map { $_ -= $i } @pi;
			$debug and print "\@pi:[@pi]\n";
			
			push @array_of_permutations, "@pi";
			}
		
		$debug and print map "$_\n", join ',', map "[$_]", @array_of_permutations;
		
		my %hash_of_permutations;
		
		for my $pi ( @array_of_permutations[ 0 .. $c_permutations - 1 ] ){
			$hash_of_permutations{ $pi } ++;
			}
		
		my $sum = 0;
		my @sums;
		
		for my $pi ( sort keys %hash_of_permutations ){
			my $value = $nxlogn{ $hash_of_permutations{ $pi } };
			$debug and print "value:$value\n";
			
			$sum += $value;
			}
		
		push @sums, $sum;
		
		for my $i ( $c_permutations .. @array_of_permutations - 1 ){
			$debug and print "i:[$i]\n";
			
			my $new = $array_of_permutations[ $i ];
			my $old = $array_of_permutations[ $i - $c_permutations ];
			
			$debug and print "old:[$old], new:[$new]\n";
			
			if( $old eq $new ){
				push @sums, $sum;
				next;
				}
			
			$sum -= $nxlogn{ $hash_of_permutations{ $new } } if exists $hash_of_permutations{ $new };
			
			$hash_of_permutations{ $new } ++;
			
			$sum += $nxlogn{ $hash_of_permutations{ $new } };
			
			$sum -= $nxlogn{ $hash_of_permutations{ $old } };
			
			$hash_of_permutations{ $old } --;
			
			delete $hash_of_permutations{ $old } if $hash_of_permutations{ $old } == 0;
			
			$sum += $nxlogn{ $hash_of_permutations{ $old } } if exists $hash_of_permutations{ $old };
			
			push @sums, $sum;
			}
		
		if( $normalize ){
			$_ /= log_base( ( eval join '*', 1 .. $m ), $log_base ) for @sums;
			};
		
		$debug and print "\@sums:[@sums]\n";
		
		print map "$_\n", join $join, @sums;
		}
}

sub log_base {
	my( $n, $base ) = @_;
	return log( $n ) / log( $base );
    }