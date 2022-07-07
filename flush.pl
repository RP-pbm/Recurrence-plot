#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for( @ARGV ){
	/^-\S/ ? ( push @opt, $_ ) : ( push @FILES, $_ );
}

my $pbm = 0;
my $to_pbm = 0;

my $top = 0;
my $bottom = 0;
my $left = 0;
my $right = 0;

my $split = " ";
my $join = " ";

for( @opt ){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-top/ and do {
		$top = 1;
	};
	/-bot(?:tom)?/ and do {
		$bottom = 1;
	};
	/-left/ and do {
		$left = 1;
	};
	/-right/ and do {
		$right = 1;
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
	
	@data = map { [ split $split ] } @data;
	
	$debug and print "@{$_}\n" for @data;
	$debug and print "---\n";
	
	if( grep { grep { not( $_ == 0 or $_ == 1 ) } @{ $_ } } @data ){
		print STDERR "warning: Not binary data!\n";
		}
	
	if( $left or $right ){
		if( $left ){
			for( @data ){
				@{ $_ } = ( ( grep $_ != 0, @{ $_ } ), ( grep $_ == 0, @{ $_ } ) );
				}
			}
		else{
			for( @data ){
				@{ $_ } = ( ( grep $_ == 0, @{ $_ } ), ( grep $_ != 0, @{ $_ } ) );
				}
			}
		}
	elsif( $top or $bottom ){
		print STDERR "'-top' and '-bottom' are not implemented! Do transpose.\n";
		}
	
	if( $to_pbm ){
		print "P1\n";
		print $cols, ' ', $rows, "\n";
	}
	
	print do { local $" = $join; "@{$_}\n" } for @data;
}
