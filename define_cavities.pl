#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @ARGV_2;
my @opt;

for (@ARGV){
	/^-\S/ ? (push @opt, $_) : (push @ARGV_2, $_);
}

my $split = ",";
my $join = ",";
my $or_zero = 1;
my $add_zero = 0;

for (@opt){
	/-or/ and do {
		$or_zero = 1;
		$add_zero = 0;
	};
	/-add/ and do {
		$add_zero = 1;
		$or_zero = 0;
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
	print map "$_\n", map { 
		chomp; join $join, map { 
			$or_zero ? $_ || 0 : $add_zero ? $_ + 0 : die "$0: No condition satf.!\n";
			} split /$split/, $_, -1 
		} 
		grep m/./, (defined $in ? <$in> : <STDIN>);
}
