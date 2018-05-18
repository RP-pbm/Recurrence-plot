#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for (@ARGV){
	/^-\S/ ? (push @opt, $_) : (push @FILES, $_);
}

my $split = " ";
my $join = " ";
my $to_pbm = 0;
my $to_pgm = 0;
my $maxval = 0;
my $maxproc;
my $findmax = 0;
my $treshold = 0;
my $gt_treshold = 1;
my $ge_treshold = 0;

for (@opt){
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
	};
	/-findmax/ and do {
		$findmax = 1;
	};
	/-maxval([\d.]+)/ and do {
		$maxval = $1;
	};
	/-treshold([\d.]+)/ and do {
		$treshold = $1;
	};
	/-gt/ and do {
		$gt_treshold = 1;
		$ge_treshold = 0;
	};
	/-ge/ and do {
		$gt_treshold = 0;
		$ge_treshold = 1;
	};
	/-max([\d.]+)%/ and do {
		$maxproc = $1;
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
	/-nosep/ and do {
		$join = '';
	};
	/-d$/ and $debug = 1;
}

for (@FILES){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = map { chomp; [ split $split ] } grep m/./, (defined $in ? <$in> : <STDIN>);
	
	$findmax and $maxval = (sort {$b <=> $a} map @{$_}, @data)[ 0 ];
	
	$treshold *= $maxval;
	
	if( $to_pbm ){
		print "P1\n";
		print 0 + @{ $data[0] }, ' ', 0 + @data, "\n";
	}
	if( $to_pgm ){
		print "P2\n";
		print 0 + @{ $data[0] }, ' ', 0 + @data, "\n";
		print 255, "\n";
	}
	
	if( defined $maxproc ){
		my @sorted = (sort {$b <=> $a} map @{$_}, @data);
		$treshold = $sorted[ @sorted * 0.01 * $maxproc ];
	}

	for (@data){
		print join "$join",
			map {
				$to_pbm ?
					( 
						$gt_treshold ?
							( $_ > $treshold ? 1 : 0 )
							:
							( $_ >= $treshold ? 1 : 0 )
					)
				:
					( 255 - int 255 * $_ / $maxval )
			} @{$_};
		print "\n";
	}
}
