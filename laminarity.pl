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
my $min_length = 2;
my $printf = '%f';
my $rr = 0;
my $pbm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $histogram = 0;
my $visual = 0;
my $longest = 0;
my $trapping_time = 0; # average
my $ratio = 0;
my $entropy = 0;

for( @opt ){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
	};
	/-rr/ and do {	# only to print recurrence rate
		$rr = 1;
	};
	/-minl.*?(\d+)/ and do {
		$min_length = $1;
	};
	/-f(\S+)/ and do {
		$printf = "%$1";
	};
	/-hist(v)?/ and do {
		$histogram = 1;
		defined $1 and $visual = 1;
	};
	/-longest/ and do {
		$longest = 1;
	};
	/-avg|-average|-tt/ and do {
		$trapping_time = 1;
	};
	/-ratio/ and do {
		$ratio = 1;
	};
	/-entropy/ and do {
		$entropy = 1;
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
	else{
		( $rows, $cols ) = ( 0 + @data, 0 + split $split, $data[0] );
	}
	
	my $size = $rows * $cols;
	
	$debug and print "----------\n";
	$debug and print "$_\n" for @data;
	$debug and print "---\n";
	
	s/ //g for @data;
	
	my $cnt_1 = 0;
	$cnt_1 += () = /1/g for @data;
	
	$rr and do { printf "${printf}\n", $cnt_1 / $size ; next };
	
	if( $to_pbm or $to_pgm ){
		s/1{$min_length,}/ 'y' x length $& /ge for @data;
		
		$debug and print "Marked:\n";
		$debug and print "$_\n" for @data;
	}
	
	if( $to_pbm ){
		print "P1\n";
		print $cols, ' ', $rows, "\n"; 
		
		y/1y/01/ for @data;
		
		print map "$_\n", map { join $join, split // } $_ for @data;
		
		next;
	}
	
	if( $to_pgm ){
		print "P2\n";
		print $cols, ' ', $rows, "\n";
		print 4, "\n";
		
		y/01y/430/ for @data;
		
		print map "$_\n", map { join $join, split // } $_ for @data;
		
		next;
	}
	
	my %lengths;
	my $sum = 0;
	my @lines = map { /1{$min_length,}/g } @data;
	map { my $len = length; $sum += $len; $lengths{ $len } ++ } 
		@lines;
	
	my $laminarity = $cnt_1 ? $sum / $cnt_1 : -1;
	printf "${printf}\n", $laminarity;
	
	if( $longest ){
		my $max_length = ( sort { $b <=> $a } keys %lengths )[ 0 ] || -1;
		print "Longest: $max_length\n";
	}
	
	if( $trapping_time ){
		printf "Trapping time (avg): ${printf}\n", @lines ? $sum / @lines : -1;
	}
	
	if( $ratio ){
		printf "Ratio: ${printf}\n", $cnt_1 ? $laminarity * $size / $cnt_1 : -1;
	}
	
	if( $entropy ){
		printf "Entrophy: ${printf}\n", !keys %lengths ? -1 : 0 - eval join ' + ', 
			map { $lengths{ $_ } * log $lengths{ $_ } } keys %lengths;
	}
	
	if( $histogram ){
		my $max_length = ( sort { $b <=> $a } keys %lengths )[ 0 ] || 0;
		printf "%3d : %s\n", $_, map { $visual ? '*' x $_ : ( sprintf "%3d", $_ ) } 
			exists $lengths{ $_ } ? $lengths{ $_ } : 0 
			for $min_length .. $max_length;
	}
	
}
