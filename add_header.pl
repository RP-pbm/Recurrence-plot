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
my $cr = 1;
my $pbm = 0;

for( @opt ){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-rc/ and do {
		$cr = 0;
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
	
	my @data = map { chomp; [ split $split ] } ( defined $in ? <$in> : <STDIN> );
	
	if( $pbm ){
		print "P1\n";
		}
	
	print join ' ', ( 0 + @{ $data[0] }, 0 + @data )[ 1 - $cr, $cr - 0 ];
	print "\n";
	
	print map "$_\n", join $join = $split, @{$_} for @data;
}

