#!/usr/bin/perl

use strict;
use warnings;

my $debug = 0;

my @ARGV_2;
my @opt;

for (@ARGV){
	/^-\S/ ? (push @opt, $_) : (push @ARGV_2, $_);
}

my $split = " ";
my $join = " ";
my $pbm = 0;

for (@opt){
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

@ARGV = @ARGV_2;

for (@ARGV){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	
	my @data;
	my $i = 0;
	my @pbm_header;
	
	for (defined $in ? <$in> : <STDIN>){
		
		if( $pbm and $i ++ <= 1 ){
			push @pbm_header, $_;
			next;
			}
			
		chomp;
		my $j = 0;
		
		for ( split /$split/ ){
			push @{$data[ $j++ ]}, $_;
		}		
	}

	print for @pbm_header;
	do { local $\ = $/; print join $join, @{$_} } for @data;
}

