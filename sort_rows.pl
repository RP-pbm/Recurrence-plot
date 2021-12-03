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
my $asc = 1;
my $desc = 0;

for( @opt ){
	/-asc/ and do {
		$asc = 1;
		$desc = 0;
	};
	/-desc/ and do {
		$asc = 0;
		$desc = 1;
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
	
	@data = map { [ split $split ] } @data;
	
	if( $asc ){
		@{ $_ } = sort { $a <=> $b } @{ $_ } for @data;
		}
	elsif( $desc ){
		@{ $_ } = sort { $b <=> $a } @{ $_ } for @data;
		}
	
	print map "$_\n", join $join, @{ $_ } for @data;
}
