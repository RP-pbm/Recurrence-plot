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
my $tau;

for( @opt ){
	/-tau(\d+)/ and do {
		$tau = $1;
	};
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
		( $rows, $cols ) = ( ~~ @data, ~~ split $split, $data[0] );
		}
	
	if( $rows != $cols ){
		die "Should be square matrix (or auto-RP)!\n";
		}
	
	@data = map { [ split $split ] } @data;
	
	my @tau_RR;
	
	for my $tau ( defined $tau ? $tau : 1 .. $rows - 1 ){
		my $tau_RR = 0;
		for my $i ( 0 .. $rows - 1 - $tau ){
			$tau_RR += $data[ $i ][ $i + $tau ];
			}
		push @tau_RR, $tau_RR / ( $rows - $tau );
		}
	
	print map "$_\n", join $join, @tau_RR;
}
