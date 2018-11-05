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
my $pbm = 0;
my $to_pbm = 0;

for( @opt ){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
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
	
	if( $to_pbm and ! $pbm ){
		( $rows, $cols ) = ( ~~ @data, ~~ split $split, $data[0] );
		}
	
	if( $to_pbm ){
		print "P1\n";
		print "$cols $rows\n";
	}
	print "$_\n" for reverse @data;
}
