#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for (@ARGV){
	/^-/ ? (push @opt, $_) : (push @FILES, $_);
}

my $split = " ";
my $join = " ";
my $min_length = 2;
my $printf = '%f';
my $rr = 0;
my $pbm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $hist = 0;
my $visual = 0;
my $longest = 0;
my $avg = 0; # average
my $ratio = 0;
my $entropy = 0;

for (@opt){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
	};
	/-rr/ and do {	# only to show recurrence rate
		$rr = 1;
	};
	/-minl.*(\d+)/ and do {
		$min_length = $1;
	};
	/-f(\S+)/ and do {
		$printf = "%$1";
	};
	/-hist(v)?/ and do {
		$hist = 1;
		defined $1 and $visual = 1;
	};
	/-longest/ and do {
		$longest = 1;
	};
	/-avg|-average/ and do {
		$avg = 1;
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

for (@FILES){
	my $in;
	/^-$/ or open $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my @data = grep m/./, (defined $in ? <$in> : <STDIN>);
	chomp @data;
	
	my( $rows, $cols );
	if( $pbm ){
		shift @data;
		( $rows, $cols ) = reverse split ' ', shift @data;
	}
	else{
		( $rows, $cols ) = ( 0 + @data, 0 + split /$split/, $data[0] );
	}
	
	my $size = $rows * $cols;
	
	@data = map { [ split /$split/ ] } @data;
	
	$debug and print "@{$_}\n" for @data;
	$debug and print "---\n";
	
	my $data = join "\n", map { join '', @{ $_ } } @data;
	
	my $cnt_1 = () = $data =~ /1/g;
	
	$rr and do { printf "${printf}\n", $cnt_1 / $size ; next };
	
	# ***** skew and rotate-cw begin *****
	my $skewed = $data =~ s/\n/ '*' x $cols /ger;
	my $wide = $rows + $cols - 1;
	if( $debug ){
		print "Wide: $wide\n";
		print $skewed =~ s/.{$wide}\K/\n/gr;
	}
	
	my $i = 0;
	my @rotcw = ('') x $wide;
	while( length( my $chop = chop $skewed ) ){
		$rotcw[ $wide - $i ++ % $wide - 1 ] .= $chop;
	}
	$debug and print "i: $i\n";
	$debug and print "$_\n" for @rotcw;
	# ***** skew and rotate-cw end *****

	$data = join "\n", @rotcw;
	
	if( $to_pbm or $to_pgm ){
		$data =~ s/1{$min_length,}/ 'y' x length $& /ge;
		
		$debug and print "Marked:\n";
		$debug and print "$data\n";
		
		my $i = 0;
		my @rotccw = ('') x $rows;
		while( length( my $chop = chop $data ) ){
			next if $chop eq "\n";
			$rotccw[ $rows - $i ++ % $rows- 1 ] =~ s/$/$chop/;
		}
		$debug and print "Rotated ccw:\n";
		$debug and print "$_\n" for @rotccw;
		
		$data = join "\n", @rotccw;
		
		$data =~ s/\*//g;
		
		$debug and print "Aligned:\n$data\n";
	}
	
	if( $to_pbm ){
		print "P1\n";
		print $cols, ' ', $rows, "\n"; 
		
		$data =~ y/1y/01/;
		
		print map "$_\n", map { join $join, split // } $_ for split "\n", $data;
		
		next;
	}
	
	if( $to_pgm ){		
		print "P2\n";
		print $cols, ' ', $rows, "\n";
		print 4, "\n";
		
		$data =~ y/01y/430/;
		
		print map "$_\n", map { join $join, split // } $_ for split "\n", $data;
		
		next;
	}
	
	my %lengths;
	my $sum = 0;
	my @lines;
	map { my $len = length; $sum += $len; $lengths{ $len } ++ } 
		@lines = $data =~ /1{$min_length,}/g;
	
	my $determinism = $sum / $cnt_1;
	printf "${printf}\n", $determinism;
	
	if( $longest ){
		my $max_length = ( sort { $b <=> $a } keys %lengths )[ 0 ] || 0;
		print "Longest: $max_length\n";
	}
	
	if( $avg ){
		printf "Average length: ${printf}\n", $sum / @lines;
	}

	if( $ratio ){
		printf "Ratio: ${printf}\n", $determinism * $size / $cnt_1;
	}
	if( $entropy ){
		printf "Entrophy: ${printf}\n",  0 - eval join ' + ', 
			map { $lengths{ $_ } * log $lengths{ $_ } } keys %lengths;
	}
	
	if( $hist ){
		my $max_length = ( sort {$b <=> $a} keys %lengths )[ 0 ] || 0;
		printf "%3d : %s\n", $_, map { $visual ? '*' x $_ : ( sprintf "%3d", $_ ) } 
			exists $lengths{ $_ } ? $lengths{ $_ } : 0 
			for $min_length .. $max_length;
	}
}
