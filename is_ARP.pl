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
my $pbm = 0;

for( @opt ){
	/-pbm/ and do {
		$pbm = 1;
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
	/-d$/ and $debug = 1;
}

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = grep m/./, ( defined $in ? <$in> : <STDIN> );
	chomp @data;
	
	my $is_ARP = 1;
	
	my( $rows, $cols );
	
	if( $pbm ){
		shift @data;
		( $rows, $cols ) = reverse split ' ', shift @data;
	}
	else{
		( $rows, $cols ) = ( 0 + @data, 0 + split $split, $data[0] );
	}
	
	$debug and print "----------\n";
	$debug and print "$_\n" for @data;
	$debug and print "---\n";
	
	if( $rows != $cols ){
		print "Not an auto-RP: number of columns != number of rows.\n";
		next;
		}
	
	@data = map { [ split $split ] } @data;
	
	for my $row ( 1 .. $rows ){
		for my $col ( 1 .. $cols ){
			$is_ARP &&= 
				$data[ $row - 1 ][ $col - 1 ] == 
				$data[ $rows - $col - 0 ][ $cols - $row - 0 ];
			last if !$is_ARP;
			}
		}
	
	if( $is_ARP ){
		print "It is an auto-RP.\n";
		}
	else{
		print "It is NOT an auto-RP.\n"
		}
}
