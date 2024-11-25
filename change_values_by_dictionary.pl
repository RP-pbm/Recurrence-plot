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
my $dict = "dict.txt";

for( @opt ){
    /-dict=(\S+)/ and do {
		$dict = $1;
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

open my $dict_file, '<', $dict or die "$0: [$dict] ... : $!\n";
my %change_name;
while(<$dict_file>){
	my( $key, $value ) = split $split;
	$change_name{ $key } = $value;
    }

for( @FILES ){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = map { chomp; [ split $split ] } grep m/./, 
		( defined $in ? <$in> : <STDIN> );

	for my $row ( @data ){
	    
		for my $col ( @{ $row } ){
			exists $change_name{ $col } and $col = $change_name{ $col };
			}
		}
	
	print map "$_\n", join $join, @{ $_ } for @data;
}
