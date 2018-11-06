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
my $printf = '%f';
my $pbm = 0;

for( @opt ){
	/-x$|-n$|-dots/ and do {
		$dots = 1;
	};
	/-f(\S+)/ and do {
		$printf = "%$1";
	};
	/-pbm/ and do {
		$pbm = 1;
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
	
	my @whites_blacks = ( 0, 0 );
	
	/ (0|1) (?{ $whites_blacks[ $1 ] ++ }) (*FAIL) /x for @data;
	
	my $all_dots = $whites_blacks[0] + $whites_blacks[1];
	
	$dots and $printf = "%d";
	printf "${printf}\n", $whites_blacks[1] / ( $dots ? 1 : $all_dots );
}
