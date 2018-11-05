#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for( @ARGV ){
	/^-\S/ ? ( push @opt, $_ ) : ( push @FILES, $_ );
}

my $top = 0;
my $bottom = 0;
my $left = 0;
my $right = 0;

my $split = " ";
my $join = " ";

for( @opt ){
	/-top(\d+)/ and do {
		$top = $1;
	};
	/-bot(\d+)/ and do {
		$bottom = $1;
	};
	/-left(\d+)/ and do {
		$left = $1;
	};
	/-right(\d+)/ and do {
		$right = $1;
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
	splice @data, 0, $top;
	splice @data, -$bottom if $bottom;
	splice @{$_}, 0, $left for @data;
	$right and
	splice @{$_}, -$right for @data;

	print do { local $" = $join; "@{$_}" }, "\n" for @data;
}
