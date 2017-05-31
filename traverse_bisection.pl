#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @ARGV_2;
my @opt;

for (@ARGV){
	/^-\S/ ? (push @opt, $_) : (push @ARGV_2, $_);
}

my $split = " ";
my $join = " ";
my $pbm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $till_end = 1;

for (@opt){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-notillend/ and do {
		$till_end = 0;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
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

@ARGV = @ARGV_2;

for (@ARGV){
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
		( $rows, $cols ) = (0 + @data, 0 + split /$split/, $data[0] );
	}

	@data = map { [ split /$split/ ] } @data;
	
	if( $to_pgm ){
		print "P2\n";
		print $cols, ' ', $rows, "\n";
		print 255, "\n";
	}
	
	my $corner = 4;
	my $grey = 2;
	my $grey_on_dot = 3;

	$debug and print "@{$_}\n" for @data;
	$debug and print "---\n";

	@data = reverse @data;
	
##	my $saved_corner;
##	if( $till_end ){
##		$saved_corner = $data[ $rows-1 ][ $cols-1 ];
##		$data[ $rows-1 ][ $cols-1 ] = 1;
##	}
	
	my( $x, $y ) = (0, 0);
	my $dist = 0;
	my @coords;
	
	while( $x < $rows and $y < $cols ){
	$debug and print "$x < $rows and $y < $cols | dist: $dist\n";
	my $found = 0;	
	
		for my $step (0 .. $dist){
			my $frow = $data[ $x - $step ][ $y - 0 ];
			my $fcol = $data[ $x - 0 ][ $y - $step ];
			next if not $frow || $fcol;
		
			my( $nx, $ny );
			if( $frow and $fcol ){
				$data[ $x ][ $y ] = $corner;
				push @coords, [ $x, $y ];
				( $nx, $ny ) = ( $x + 1, $y + 1 );
				$step = 0;
			}
			elsif( $frow ){
				$data[ $x - $step ][ $y ] = $corner;
				push @coords, [ $x - $step, $y ];
				( $nx, $ny ) = ( $x + 1 - $step , $y + 1 );
				$step = 0;
			}
			elsif( $fcol ){
				$data[ $x ][ $y - $step ] = $corner;
				push @coords, [ $x, $y - $step ];
				( $nx, $ny ) = ( $x + 1, $y + 1 - $step);
				$step = 0;
			}
		
			for my $i ($x - $dist .. $nx - 1){
				for my $j ($y - $dist .. $ny - 1){
				#%	print "$data[$i][$j] == 0 and $data[$i][$j] = 2;\n";
					$data[$i][$j] == 0 and $data[$i][$j] = $grey;
					$data[$i][$j] == 1 and $data[$i][$j] = $grey_on_dot;
				}
			}
		
			$debug and do { print "@{$_}\n" for reverse @data };
		
			( $x, $y ) = ( $nx, $ny );
		
			$found = 1;
			last;
		}
	
		$found ? $dist = 0 : $dist ++;
		$found or ( $x, $y ) = ( $x + 1, $y + 1 );
	
	}
	
##	if( $till_end ){
##		$saved_corner == 0 and $saved_corner = $grey;
##		$saved_corner == $corner and $saved_corner = $grey_on_dot;
##		$data[ $rows-1 ][ $cols-1 ] = $saved_corner;
##	}
	
	@data = reverse @data;

	if( $to_pgm ){
		my %convert = (
			0, 255,
			1, 120,
			$grey, 160,
			$grey_on_dot, 80,
			$corner, 0,
		);
		for (@data){
			map { $_ = $convert{ $_ } } @{$_};
		}
	}

	print do { local $" = $join; "@{$_}\n" } for @data;

	if( !$to_pgm ){
		print map "[$_]", join ',', map "($_)", 
			map { join ',', map $_ + 1, @{$_} } @coords;
		print "\n";
	}
}
