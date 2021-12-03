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
my $pbm = 0;
my $whole = 0;
my $window = 1;

for( @opt ){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-whole/ and do {
		$whole = 1;
	};
	/-window(\d+)/ and do {
		$window = $1;
	};
	/-F(\S+)/ and do {
		$split = $1;
	};
	/-toF(\S+)/ and do {
		$join = $1;
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

if( @FILES != 3 ){
	die "\@FILES != 3; There must be ARP_X, ARP_Y and JRP_X_x_Y files.\n";
	}

$debug and print "\@FILES: @FILES\n";

while( @FILES ){
	my( $file_1, $file_2, $file_3 ) = ( shift @FILES, shift @FILES, shift @FILES );
	open my $in0, '<', $file_1 or die "$0: can't open $file_1\n";
	open my $in1, '<', $file_2 or die "$0: can't open $file_2\n";
	open my $in2, '<', $file_3 or die "$0: can't open $file_3\n";
	my @data;
	push @data, [ map { chomp; [ split $split ] } 
		grep m/./, <$_> ] for $in0, $in1, $in2;
	
	my @cols;
	my @rows;
	
	for my $file ( 0 .. 2 ){
		if( $pbm ){
			( $cols[ $file ], $rows[ $file ] ) = @{ $data[ $file ][ 1 ] };
			shift @{ $data[ $file ] };
			shift @{ $data[ $file ] };
			}
		else{
			( $cols[ $file ], $rows[ $file ] ) = 
			( ~~ @{ $data[ $file ][ 0 ] }, ~~ @{ $data[ $file ] } )
			}
		$debug and print "cols: $cols[$file], rows: $rows[$file]\n";
		}
	
	if( $rows[ 0 ] != $rows[ 1 ] or $rows[ 1 ] != $rows[ 2 ] ){
		die "Number of rows must be equal in all matrices (RPs)!\n";
		}
	
	# MCR:
	
	if( $whole ){
		my $MCR_YofX = 0;
		my $MCR_XofY = 0;
		
		for my $i ( 0 .. $rows[ 0 ] - 1 ){
			my $JR = 0;
			for my $j ( 0 .. $rows[ 0 ] - 1 ){
				$JR += $data[ 2 ][ $i ][ $j ];
				}
			my $RX = 0;
			for my $j ( 0 .. $rows[ 0 ] - 1 ){
				$RX += $data[ 0 ][ $i ][ $j ];
				}
			my $RY = 0;
			for my $j ( 0 .. $rows[ 0 ] - 1 ){
				$RY += $data[ 1 ][ $i ][ $j ];
				}
			
			$RX > 0 and $MCR_YofX += $JR / $RX;
			$RY > 0 and $MCR_XofY += $JR / $RY;
			}
		
		$_ /= $rows[ 0 ] for $MCR_YofX, $MCR_XofY;
		
		print map "$_\n", join $join, $MCR_YofX, $MCR_XofY;
		}
	else{
		
		my @MCR_YofX;
		my @MCR_XofY;
		
		for my $ii ( 0 .. $rows[ 0 ] - 1 - $window + 1 ){
			
			# almost-COPY begin:
			
			my $MCR_YofX = 0;
			my $MCR_XofY = 0;
			
			for my $i ( $ii .. $ii + $window - 1 ){
				my $JR = 0;
				for my $j ( $ii .. $ii + $window - 1 ){
					$JR += $data[ 2 ][ $i ][ $j ];
					}
				my $RX = 0;
				for my $j ( $ii .. $ii + $window - 1 ){
					$RX += $data[ 0 ][ $i ][ $j ];
					}
				my $RY = 0;
				for my $j ( $ii .. $ii + $window - 1 ){
					$RY += $data[ 1 ][ $i ][ $j ];
					}
				
				$RX > 0 and $MCR_YofX += $JR / $RX;
				$RY > 0 and $MCR_XofY += $JR / $RY;
				}
			
			$_ /= $rows[ 0 ] for $MCR_YofX, $MCR_XofY;
			
			# almost-COPY end;
			
			push @MCR_YofX, $MCR_YofX;
			push @MCR_XofY, $MCR_XofY;
			}
		
		print map "$_\n", join $join, @MCR_YofX;
		print map "$_\n", join $join, @MCR_XofY;
		}
}

