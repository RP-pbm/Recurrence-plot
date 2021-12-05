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
my $clip = 0;
my $each = 0;

# Usage: first file = original (with zeroes), second file = AR1.

for( @opt ){
	/-clip(\d+)/ and do {
		$clip = $1;
	};
	/-each/ and do {
		$each = 1;
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

if( @FILES != 2 ){
	die "\@FILES != 2; There must be two data files.\n";
	}
	
	$debug and print "<<@FILES>>\n";
	
	open my $in0, '<', $FILES[0] or die "$0: Can't open '$FILES[0]' : $!\n";
	open my $in1, '<', $FILES[1] or die "$0: Can't open '$FILES[1]' : $!\n";
	my @data;
	push @data, [ map { chomp; $_ } grep m/./, <$_> ] for $in0, $in1;
	
	my @cols;
	my @rows;
	
	for my $u ( 0 .. 1 ){
		@{ $data[$u] } = map { [ split $split ] } @{ $data[$u] };
		$debug and print "@{$_}\n" for @{ $data[$u] };
		}
	
	for my $u ( 0 .. 1 ){
		( $cols[$u], $rows[$u] ) = ( ~~ @{ $data[$u][0] }, ~~ @{ $data[$u] } );
		$debug and print "[( $cols[$u], $rows[$u] )]\n";
		}
		
	if( $rows[0] != $rows[1] ){
		die "Number of rows must be equal!\n";
		}
	
	if( $cols[0] != $cols[1] ){
		die "Number of columns must be equal!\n";
		}
	
	if( $each == 1 ){
		for my $i ( 1 .. $rows[0] ){
			my $zeroes = grep { $_ == 0 } @{ $data[0][ $i-1 ] };
			my @sorted_values = sort { $a <=> $b } @{ $data[1][ $i-1 ] };
			$_ -= $sorted_values[ $zeroes ] for @{ $data[1][ $i-1 ] };
			$_ < 0 and $_ = 0 for @{ $data[1][ $i-1 ] };
			
			print map "$_\n", join $join, @{ $data[1][ $i-1 ] };
			}
		}
	else{
		my @col_sum;
		for my $j ( 1 .. $cols[0] ){
			my $col_sum = 0;
			for my $i ( 1 .. $rows[0] ){
				$col_sum += $data[0][ $i-1 ][ $j-1 ];
				}
			push @col_sum, $col_sum;
			}
		
		my $empties = grep { $_ == 0 } @col_sum;
		
		@col_sum = ();
		
		for my $j ( 1 .. $cols[0] ){
			my $col_sum = 0;
			for my $i ( 1 .. $rows[0] ){
				$col_sum += $data[1][ $i-1 ][ $j-1 ];
				}
			push @col_sum, $col_sum;
			}
		
		my $i = 1;
		@col_sum = map { [ $i++, $_ ] } @col_sum;
		
		@col_sum = sort { $a->[1] <=> $b->[1] } @col_sum;
		
		my $diff = $col_sum[ $empties - 1 ][1];
		
		$_->[1] -= $diff for @col_sum;
		$_->[1] < 0 and $_->[1] = 0 for @col_sum;
		
		my $debug_cnt = 0;
		
		for my $j ( map $_->[0], grep { $_->[1] <= 0 } @col_sum ){
			$debug_cnt ++;
			for my $i ( 1 .. $rows[0] ){
				$data[1][ $i-1 ][ $j-1 ] = 0;
				}
			}
		
		$debug and print "empties:[$empties];cnt:[$debug_cnt]\n";
		
		for my $i ( 1 .. $rows[0] ){
			print map "$_\n", join $join, @{ $data[1][ $i-1 ] };
			}
		}
	
	