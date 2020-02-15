#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for( @ARGV ){
	/^-\S/ ? ( push @opt, $_ ) : ( push @FILES, $_ );
}

my $dots = 0;
my $array = 0;
my $printf = '%f';
my $pbm = 0;

my $split = " ";
my $join = " ";

for( @opt ){
	/-x$|-n$|-dots/ and do {
		$dots = 1;
	};
	/-j$|-h$|-array/ and do {
		$array = 1;
	};
	/-f(\S+)/ and do {
		$printf = "%$1";
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
	/-d$/ and $debug = 1;
}

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = map { chomp; $_ } grep m/./, ( defined $in ? <$in> : <STDIN> );
	
	my( $rows, $cols );
	
	if( $pbm ){
		shift @data;
		( $rows, $cols ) = reverse split ' ', shift @data;
		}
	
	@data = map { [ split $split, $_, -1 ] } @data;
	
	if( ! $pbm ){
		$rows = @data;
		$cols = @{ $data[ 0 ] };
		}
	
	my @blacks;
	
	for( @data ){
		my $blacks = grep $_ == 1, @{ $_ };
		
		push @blacks, $blacks;
		}
	
	if( ! $array ){
		@blacks = eval join '+', @blacks;
		}
	
	$dots and $printf = "%d";
	print map "$_\n", join $join, 
		map { sprintf "${printf}", $_ / ( $dots ? 1 : $rows * $cols ) } @blacks;
}
