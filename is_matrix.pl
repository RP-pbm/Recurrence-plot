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

for( @opt ){
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
	my @lengths = map { chomp; 0 + split $split } 
		grep m/./, ( defined $in ? <$in> : <STDIN> );
	
	my $rows = @lengths;
	my $ok = @lengths == grep { $lengths[0] == $_ } @lengths;
	
	print $ok ? "Matrix: ${lengths[0]} (columns) x ${rows} (rows)\n"
		: "Not a matrix\n";
}
