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
my $to_pbm = 0;
my $to_pgm = 0;
my $max_val;

for( @opt ){
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
	};
	/-maxval(\d+)/ and do {
		$max_val = $1;
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
	
	my @data = map { chomp; [ split $split ] } grep /./, ( defined $in ? <$in> : <STDIN> );
	
	if( $to_pbm ){
		print "P1\n";
		}
	
	if( $to_pgm ){
		print "P2\n";
		}
	
	print join ' ', ( 0 + @{ $data[0] }, 0 + @data )[ 1 - $cr, $cr - 0 ];
	print "\n";
	
	if( $to_pgm ){
		$max_val //= ( sort { $b <=> $a } map @{ $_ }, @data )[ 0 ];
		print $max_val . "\n";
		}
	
	print map "$_\n", join $join = $split, @{$_} for @data;
}

