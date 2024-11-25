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
my $wNames = 0;
my $union = 1;
my $intersection = 0;
my $diffs = 0;
my $all = 0;

for( @opt ){
	/-wNames/ and do {
		$wNames = 1;
	};
	/-union/ and do {
		$union = 1;
		$intersection = 0;
		$diffs = 0;
	};
	/-intersection/ and do {
		$union = 0;
		$intersection = 1;
		$diffs = 0;
	};
	/-diff(?:erence)?s/ and do {
		$union = 0;
		$intersection = 0;
		$diffs = 1;
	};
	/-all/ and do {
		$all = 1;
		$union = 1;
		$intersection = 1;
		$diffs = 1;
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
	
	my $c = 0;
	
	if( $wNames ){
		my %h;
		
		for my $row ( @data ){
			$h{ $row->[ $c ] }{ $row->[ $c + 1 ] } ++;
			}
		
		if( $union ){
			print $_, $join, ( join '/', sort keys %{ $h{ $_ } } ), "\n" for sort keys %h;
			}
		$all and print "\n";
			
		if( $intersection ){
			for( sort keys %h ){
				my @names = sort keys %{ $h{ $_ } };
				next if @names < 2;
				print $_, $join, ( join '/', @names ), "\n";
				}
			}
		$all and print "\n";
		
		if( $diffs ){
			my %names;
			for( sort keys %h ){
				$names{ $_ } ++ for sort keys %{ $h{ $_ } };
				}
			for my $name ( sort keys %names ){
				for( sort keys %h ){
					next if not exists $h{ $_ }{ $name };
					my @names = sort keys %{ $h{ $_ } };
					next if @names > 1;
					print $_, $join, $name, "\n";
					}
				print "\n";
				}
			}
		}
	else{
		my %h;
		
		for my $row ( @data ){
			$h{ $row->[ $c ] } ++;
			}
		
		if( $union ){
			print $_, "\n" for sort keys %h;
			}
		if( $intersection ){
			print $_, "\n" for grep { $h{ $_ } > 1 } sort keys %h;
			}
		if( $diffs ){
			print STDERR "$0: [$_] -diffs can't be used without set names!\n";
			}
		}
}

