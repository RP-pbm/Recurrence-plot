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
my $autocorr = 1;
my $lag = 1;
my $normalize = 1;

for( @opt ){
	/-noautocorr/ and do {
		$autocorr = 0;
	};
	/-lag(\d+)/ and do {
		$lag = $1;
	};
	/-no-normalize/ and do {
		$normalize = 0;
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
	my @data = map { chomp; [ split $split ] } grep m/./, ( defined $in ? <$in> : <STDIN> );
	
	if( $lag != 1 ){ die "Not implemented for lag != 1.\n" }
	if( $autocorr != 1 ){ die "Not implemented without autocorrelation.\n" }
	
	for my $row ( @data ){
		my $avg = ( eval join ' + ', @{$row} ) / @{$row};
		
		my $avg_1 = ( eval join ' + ', @{$row}[0 .. @{$row} - 2] ) / ( @{$row} - 1 );
		my $avg_2 = ( eval join ' + ', @{$row}[1 .. @{$row} - 1] ) / ( @{$row} - 1 );
		$debug and print "avg 1 2: $avg_1, $avg_2\n";
		
		my $sum_12 = 0;
		
		for my $i ( 0 .. @{$row} - 2 ){
			$sum_12 += ( $row->[$i] - $avg_1 ) * ( $row->[$i + 1] - $avg_2 );
			}
		
		my $sum_1 = 0;
		my $sum_2 = 0;
		
		for my $i ( 0 .. @{$row} - 2 ){
			$sum_1 += ( $row->[$i] - $avg_1 ) ** 2;
			$sum_2 += ( $row->[$i + 1] - $avg_2 ) ** 2;
			}
		
		# if all numbers in a row are equal
		if( !$sum_1 or !$sum_2 ){
			print map "$_\n", join $join, @{$row};
			next;
			}
		
		my $rho = $sum_12 / ( sqrt( $sum_1 ) * sqrt( $sum_2 ) );
		$debug and print "rho: $rho\n";
		
		@_ = 0 .. @{$row} - 1;
		for my $i ( reverse 1 .. @{$row} ){
			my $x = int rand $i;
			( $_[ $x ], $_[ $i - 1 ] ) = ( $_[ $i - 1 ], $_[ $x ] );
			}
		$debug and print "shuffles: [@_]\n";
		$debug and print "original: [@{$row}]\n";
		
		@{$row} = @{$row}[ @_ ];
		
		$debug and print "shuffled: [@{$row}]\n";
		
		if( $normalize ){
			map { $_ -= $avg } @{$row};
			}
		
		$debug and printf "min & max: %s & %s\n", ( sort { $a <=> $b } @{$row} )[ 0, -1 ];
		
	#!	$debug and print "minus-avg: [@{$row}]\n";
		$debug and printf "minus-avg: [%s]\n", join ' ', 
			map { sprintf "%.3f", $_ } @{$row};
		
		my @Y = ( $row->[0] );
		
		for my $i ( 1 .. @{$row} - 1 ){
			push @Y, $rho * $Y[-1] + $row->[ $i ];
			}
		
		my $Ysum = eval join ' + ', @Y;
		$debug and print "Ysum: $Ysum\n";
		
	#!	my $Ymin = ( sort { $a <=> $b } @Y )[ 0 ];
	#!	map { $_ += abs $Ymin } @Y;
		
		print map "$_\n", join $join, map { sprintf "%.3f", $_ } @Y;
		
		}

}
