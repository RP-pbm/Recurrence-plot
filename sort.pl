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
my $by_col = 1;
my $num = 1;
my $lex = 0;
my $asc = 1;
my $desc = 0;

for( @opt ){
	/-by-col(\d+)/ and do {
		$by_col = $1;
	};
	/-num/ and do {
		$num = 1;
		$lex = 0;
	};
	/-lex/ and do {
		$num = 0;
		$lex = 1;
	};
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
	my @data = map { chomp; [ split $split ] } grep m/./, 
		( defined $in ? <$in> : <STDIN> );
	
	my $c = $by_col - 1;
	
	if( $num ){
		if( $asc ){
			@data = sort { $a->[$c] <=> $b->[$c] } @data;
			}
		elsif( $desc ){
			@data = sort { $b->[$c] <=> $a->[$c] } @data;
			}
		}
	elsif( $lex ){
		if( $asc ){
			@data = sort { $a->[$c] cmp $b->[$c] } @data;
			}
		elsif( $desc ){
			@data = sort { $b->[$c] cmp $a->[$c] } @data;
			}
		}
	
	print map "$_\n", join $join, @{ $_ } for @data;
}

