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
my $pbm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $row_step = 10;
my $col_step = 10;
my $step_proc_on = 1;
my $step_proc = 20;

for (@opt){
	/-pbm/ and do {
		$pbm = 1;
	};
	/-stepproc(\d+)/ and do {
		$step_proc_on = 1;
		$step_proc = $1;
	};
	/-rowstep(\d+)/ and do {
		$step_proc_on = 0;
		$row_step = $1;
	};
	/-colstep(\d+)/ and do {
		$step_proc_on = 0;
		$col_step = $1;
	};
	/-step(\d+)/ and do {
		$step_proc_on = 0;
		$col_step = $1;
		$row_step = $1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
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
	my @data = grep m/./, (defined $in ? <$in> : <STDIN>);
	chomp @data;
	
	my( $rows, $cols );
	if( $pbm ){
		shift @data;
		( $rows, $cols ) = reverse split ' ', shift @data;
	}
	else{
		( $rows, $cols ) = (0 + @data, 0 + split /$split/, $data[0] );
	}
	
	if( $step_proc_on ){
		$row_step = $rows * $step_proc / 100;
		$col_step = $cols * $step_proc / 100;
	}

	@data = map { [ split /$split/ ] } @data;
	
	if( $to_pgm ){
		print "P2\n";
		print $cols, ' ', $rows, "\n";
		print 255, "\n";
	}
	
	my $grey = 2;
	my $grey_on_dot = 3;
	my $grey_on_middle = 4;
	my $dot_on_middle = 5;

	$debug and print "@{$_}\n" for @data;
	$debug and print "---\n";

	@data = reverse @data;
	
	my( $x, $y ) = (0, 0);
	my @coords;
	
	while( $x < $rows and $y < $cols ){
	$debug and print "$x < $rows and $y < $cols\n";
		
		my( @rows, @cols );
		
		for my $row ($x .. $x - 1 + $row_step){
			$row > $rows - 1 and next;
			for my $col ($y .. $y - 1 + $col_step){
				$col > $cols - 1 and next;
				if( $data[ $row ][ $col ] =~ /1|$grey_on_dot/ ){
					push @rows, $row;
					push @cols, $col;
					}
				$data[ $row ][ $col ] == 0 
					and $data[ $row ][ $col ] = $grey;
				$data[ $row ][ $col ] == 1 
					and $data[ $row ][ $col ] = $grey_on_dot;
				}
			}
		
		$debug and do { print "@{$_}\n" for reverse @data };
		
		if( !@rows ){
			( $x, $y ) = ( $x + $row_step, $y + $col_step );
			next;
			}
		
		@rows = sort {$a <=> $b} @rows;
		@cols = sort {$a <=> $b} @cols;
		
		my $median_row = @rows % 2 ? $rows[ @rows / 2 ] 
			: ( $rows[ @rows / 2 - 1 ] + $rows[ @rows / 2 ] ) >> 1;
			
		my $median_col = @cols % 2 ? $cols[ @cols / 2 ] 
			: ( $cols[ @cols / 2 - 1 ] + $cols[ @cols / 2 ] ) >> 1;
		
		$data[ $median_row ][ $median_col ] =~ s/$grey/$grey_on_middle/ ||
		$data[ $median_row ][ $median_col ] =~ s/$grey_on_dot/$dot_on_middle/;
		
		$debug and print "(rows:@rows|cols:@cols)"
			. "[median_row:$median_row][median_col:$median_col]\n";
		
		push @coords, [ $median_row, $median_col ];
		( $x, $y ) = ( $median_row + 1, $median_col + 1 );
	
	}
	
	@data = reverse @data;

	if( $to_pgm ){
		my %convert = (
			0, 255,
			1, 120,
			$grey, 200,
			$grey_on_dot, 80,
			$grey_on_middle, 160,
			$dot_on_middle, 0,
		);
		for (@data){
			map { $_ = $convert{ $_ } } @{$_};
		}
	}

	print do { local $" = $join; "@{$_}\n" } for @data;

	if( !$to_pgm ){
		print map "[$_]", join ',', map "($_)", 
			map { join ',', map $_ + 1, @{$_} } @coords;
		print "\n";
	}
}
