#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @ARGV_2;
my @opt;

for (@ARGV){
	/^-\S/ ? (push @opt, $_) : (push @ARGV_2, $_);
}

my $split = " ";
my $join = " ";

for (@opt){
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

@ARGV = @ARGV_2;

for (@ARGV){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = map { chomp; [ split /$split/ ] } grep m/./, 
		(defined $in ? <$in> : <STDIN>);
	
	for my $row (@data){
		
		@_ = 0 .. @{$row} - 1;
		for my $i (reverse 1 .. @{$row}){
			my $x = int rand $i;
			( $_[ $x ], $_[ $i - 1 ] ) = ( $_[ $i - 1 ], $_[ $x ] );
			}
		$debug and print "shuffles: [@_]\n";
		$debug and print "original: [@{$row}]\n";
		
		@{$row} = @{$row}[ @_ ];
				
		print map "$_\n", join $join, @{$row};
		}

}
