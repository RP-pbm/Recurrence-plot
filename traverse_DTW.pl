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
my $pbm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $to_ppm = 0;
my $tb = 0;
my $is_tb = 0;
my $print_accumulated = 0;
my $print_synch_coords = 0;

for( @opt ){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
	};
	/-toppm/ and do {
		$to_ppm = 1;
	};
	/-tb/ and do {
		$tb = 1;
	};
	/-istb/ and do {
		$is_tb = 1;
	};
	/-accum/ and do {
		$print_accumulated = 1;
	};
	/-synch/ and do {
		$print_synch_coords = 1;
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
	my @data = grep m/./, ( defined $in ? <$in> : <STDIN> );
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
	
	$debug and print "\@data:\n";
	$debug and print "@{$_}\n" for @data;
	$debug and print "-----\n";
	
	$is_tb and @data = reverse @data;
	
	my @pbm;
	push @pbm, [ map { 0 } @{$_} ] for @data;
	
	my @pgm;
	push @pgm, [ map { ( 1 - $_ ) * 255 } @{$_} ] for @data;
	
	my @ppm;
	push @ppm, [ map { join ' ', ( ( 1 - $_ ) * 255 ) x 3 } @{ $_ } ] for @data;
	
	#*****#***** begin DTW
	
	my $max_in = 1;
#!	map { $max_in < $_ and $max_in = $_ } @{$_} for @data;
	map { $_ = $max_in - $_ } @{$_} for @data;
	
	my $inf = ~0;
#!	my $inf = 0;
	
	my @DTW;
	push @DTW, [ ( $inf ) x ( $cols + 1 ) ];
	push @DTW, [ $inf, ( 0 ) x $cols ] for 1 .. $rows;
	
	$debug and print "\@DTW:\n";
	$debug and print "@{$_}\n" for @DTW;
	$debug and print "-----\n";
	
	my $max = 0;
	
	$DTW[ 0 ][ 0 ] = 0;

	for my $i ( 1 .. $rows ){
		for my $j ( 1 .. $cols ){
			$DTW[ $i ][ $j ] = $data[ $i - 1 ][ $j - 1 ] + 
				( 
				#!	reverse
					sort { $a <=> $b } 
					$DTW[ $i - 1 ][ $j ],
					$DTW[ $i ][ $j - 1 ],
					$DTW[ $i - 1 ][ $j - 1 ],
				)[ 0 ];
			
			$DTW[ $i ][ $j ] > $max and $max = $DTW[ $i ][ $j ];
			}
		}
	
	$debug and print "\@DTW:\n";
	$debug and $is_tb and print "@{$_}\n" for reverse @DTW;
	$debug and !$is_tb and print "@{$_}\n" for @DTW;
	$debug and print "-----\n";
	
	map { $_ = int $_ / $max * 255 } @{$_} for @DTW;
	
		#***** begin synchronization-line
		my( $i, $j ) = ( $rows, $cols );
		
		my @synch_line;
		
		while( $i != 0 and $j != 0 ){
			push @synch_line, [ $i, $j ];
			
			$DTW[ $i ][ $j ] = 255;
			$pbm[ $i - 1 ][ $j - 1 ] = 1;
			$pgm[ $i - 1 ][ $j - 1 ] = 200;
			$ppm[ $i - 1 ][ $j - 1 ] =~ s/(\d+) (\d+) (\d+)/0 $2 255/;
						
			( $i, $j ) = 
					map { @{ $_->[ 0 ] } }
				#!	reverse
					sort {
						$a->[ 1 ] <=> $b->[ 1 ]
						}
						map {
						$debug and print "[@{$_}] => $DTW[ $_->[ 0 ] ][ $_->[ 1 ] ]";
						[ $_ => $DTW[ $_->[ 0 ] ][ $_->[ 1 ] ] * $_->[ 2 ] ]
						} 
							[ $i - 1, $j - 1, 1.0 ], 
							[ $i - 1, $j, 1.0 ], 
							[ $i, $j - 1, 1.0 ],
			}
		
		#***** end synchronization-line
	
	shift @DTW;
	shift @{$_} for @DTW;
	
	if( $print_synch_coords ){
		print join $join, map "[@{$_}]", @synch_line;
		next;
		}
	
	if( $print_accumulated ){
		print "P2\n";
		print $cols, ' ', $rows, "\n";
		print 255, "\n";
		$tb and print "@{$_}\n" for reverse @DTW;
		!$tb and print "@{$_}\n" for @DTW;
		next;
		}
	
	if( $to_pbm ){
		print "P1\n";
		print $cols, ' ', $rows, "\n";
		$tb and print "@{$_}\n" for reverse @pbm;
		!$tb and print "@{$_}\n" for @pbm;
	}
	
	if( $to_pgm ){
		print "P2\n";
		print $cols, ' ', $rows, "\n";
		print 255, "\n";
		$tb and print "@{$_}\n" for reverse @pgm;
		!$tb and print "@{$_}\n" for @pgm;
	}
	
	if( $to_ppm ){
		print "P3\n";
		print $cols, ' ', $rows, "\n";
		print 255, "\n";
		$tb and print "@{$_}\n" for reverse @ppm;
		!$tb and print "@{$_}\n" for @ppm;
		}
		
	#*****#***** end DTW
}
