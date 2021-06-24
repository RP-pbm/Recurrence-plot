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
my $simple_perm = 1;
my $simple_norm = 0;
my $wide_perm = 0;
my $wide_norm = 0;

for( @opt ){
	/-m(\d+)/ and do {
		$m = $1;
	};
	/-simple-perm/ and do {
		$simple_perm = 1;
	};
	/-simple-norm/ and do {
		$simple_perm = 0;
		$simple_norm = 1;
	};
	/-wide-norm/ and do {
		$simple_perm = 0;
		$wide_norm = 1;
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
	
	if( @data > 1 ){
		die "$0: Implemented to process only one line (array). $!\n";
		}
	
	my @array = @{ $data[ 0 ] };
	my $length = @array;
	
	my @result;
	push @result, [] for 1 .. $m;
	
	if( $simple_perm ){
		my $i = 0;
		@array = map { [ $_, $i ++ ] } @array;
		
		for my $i ( 0 .. @array - $m - 0 ){
			my @X_refs = @array[ map { $i + $_ } 0 .. $m - 1 ];
			$debug and print map "$_\n", join '|', map { join ' ', @{ $_ } } @X_refs;
			
			my @pi = map $_->[ 1 ], sort { $a->[ 0 ] <=> $b->[ 0 ] } @X_refs;
			$debug and print "\@pi:[@pi]\n";
			
			map { $_ -= $i } @pi;
			$debug and print "\@pi:[@pi]\n";
			
			for my $j ( 0 .. @pi - 1 ){
				push @{ $result[ $j ] }, $pi[ $j ];
				}
			}
		}
	elsif( $simple_norm ){
		for my $i ( 0 .. @array - $m - 0 ){
			my @X_refs = @array[ map { $i + $_ } 0 .. $m - 1 ];
			$debug and print "@X_refs\n";
			
			my( $min, $max ) = ( sort { $a <=> $b } @X_refs )[ 0, -1 ];
			my $diff = $max - $min;
			
			@X_refs = map { ( $_ - $min ) / $diff } @X_refs;
			$debug and print "@X_refs\n";
			
			for my $j ( 0 .. @X_refs - 1 ){
				push @{ $result[ $j ] }, $X_refs[ $j ];
				}
			}
		}
	elsif( $wide_norm or $wide_perm ){
		if( $m % 2 == 0 ){
			die "$0: Implemented for odd m values (but got $m). $!\n";
			}
		my $hand = int $m / 2;
		
		my %extremum_idxs;
		for my $i ( 1 .. @array - 2 ){
			if( $array[ $i - 1 ] < $array[ $i ] and $array[ $i ] > $array[ $i + 1 ] or
				$array[ $i - 1 ] > $array[ $i ] and $array[ $i ] < $array[ $i + 1 ]
				){
				$extremum_idxs{ $i } ++;
				}
			}
		
		for my $i ( 0 .. @array - 1 ){
			$array[ $i ] = [ $array[ $i ], exists $extremum_idxs{ $i } ? 1 : 0 ];
			}
		
		for my $i ( 0 .. @array - 1 ){
			my @L_values;
			my @R_values;
			
			for my $L ( reverse 0 .. $i - 1 ){
				last if @L_values == $hand;
				if( $array[ $L ][ 1 ] == 1 ){
					unshift @L_values, $array[ $L ][ 0 ];
					}
				}
			next if @L_values < $hand;
			
			for my $R ( $i + 1 .. @array - 1 ){
				last if @R_values == $hand;
				if( $array[ $R ][ 1 ] == 1 ){
					push @R_values, $array[ $R ][ 0 ];
					}
				}
			next if @R_values < $hand;
			
			$debug and print "[$i],L:[@L_values], $array[ $i ][0], R:[@R_values]\n";
			
			my @values = ( @L_values, $array[ $i ][ 0 ], @R_values );
			
			if( $wide_norm ){
				my( $min, $max ) = ( sort { $a <=> $b } @values )[ 0, -1 ];
				my $diff = $max - $min;
				
				@values = map { ( $_ - $min ) / $diff } @values;
				$debug and print "@values\n";
				
				for my $j ( 0 .. @values - 1 ){
					push @{ $result[ $j ] }, $values[ $j ];
					}
				}
			elsif( $wide_perm ){
				die "$0: To be implemented... $!\n";
				;;;
				}
			}
		
		}
	
	print map "$_\n", join $join, @{ $_ } for @result;
}

