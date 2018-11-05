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
my $pbm = 0;
my $to_pbm = 0;  # not relevant
my $to_pgm = 0;
my $to_ppm = 0;
my $make_gif = 0;
my $recursive = 0;
my $row_step = 10;
my $col_step = 10;
my $step_proc_on = 1;
my $step_proc = 20;

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
	/-toppm/ and do {
		$to_ppm = 1;
	};
	/-gif/ and do {
		$make_gif = 1;
	};
	/-(recursive|DnC)/i and do {
		$recursive = 1;
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
	
	@data = map { [ split $split ] } @data;
	
	$debug and print "@{$_}\n" for @data;
	$debug and print "---\n";
	
	@data = reverse @data;
	
	my @coords;
	
	my $window_on_empty = 'v';
	my $window_on_recurrence = 'W';
	my $median_on_empty = 'n';
	my $median_on_recurrence = 'M';
	
	my @gif;
	
	if( !$recursive ){ # moving window
		
		if( $step_proc_on ){
			$row_step = $rows * $step_proc / 100;
			$col_step = $cols * $step_proc / 100;
		}
		
		my( $x, $y ) = ( 0, 0 );
		
		my $i = 0;
		
		while( $x < $rows and $y < $cols ){
		$debug and print "$x < $rows and $y < $cols\n";
			
			my( @rows, @cols );
			
			my %convert = (
				0 => $window_on_empty,
				1 => $window_on_recurrence,
				$window_on_empty => $window_on_empty,
				$window_on_recurrence => $window_on_recurrence,
			);
			
			for my $row ( $x .. $x - 1 + $row_step ){
				$row > $rows - 1 and next;
				for my $col ( $y .. $y - 1 + $col_step ){
					$col > $cols - 1 and next;
					if( $data[ $row ][ $col ] =~ /1|$window_on_recurrence/ ){
						push @rows, $row;
						push @cols, $col;
						}
					
					$data[ $row ][ $col ] = $convert{ $data[ $row ][ $col ] };
					}
				}
			
			if( !@rows ){
				( $x, $y ) = ( $x + $row_step, $y + $col_step );
				next;
				}
			
			my $median_row = median( @rows );
			my $median_col = median( @cols );
			
			%convert = (
				$window_on_empty => $median_on_empty,
				$window_on_recurrence => $median_on_recurrence,
			);
			
			$data[ $median_row ][ $median_col ] = 
				$convert{ $data[ $median_row ][ $median_col ] }; 
			
			$debug and print "(rows:@rows|cols:@cols)"
				. "[median_row:$median_row][median_col:$median_col]\n";
			
			push @coords, [ $median_row, $median_col ];
			( $x, $y ) = ( $median_row + 1, $median_col + 1 );
			
			if( $make_gif ){
				push @{ $gif[ $i ] }, [ @{ $_ } ] for reverse @data;
			}
			
			$i ++;
		}
		
	}
	else{  # divide and conquire
		my @UDLR = [ 0, $rows - 1, 0, $cols - 1 ];
		
		my $i = 0;
		
		while( @UDLR ){
			my( $U, $D, $L, $R ) = @{ shift @UDLR };
			
			$debug and print "[ $U, $D, $L, $R ]\n";
			
			my( @rows, @cols );
			
			my %convert = (
				0 => $window_on_empty,
				1 => $window_on_recurrence,
				$window_on_empty => 0,
				$window_on_recurrence => 1,
			);
			
			for my $row ( $U .. $D ){
				for my $col ( $L .. $R ){
					
					if( $data[ $row ][ $col ] =~ /1|$window_on_recurrence/ ){
						push @rows, $row;
						push @cols, $col;
						}
					
					$data[ $row ][ $col ] = $convert{ $data[ $row ][ $col ] }; 
					}
				}
			
			next if !@rows || !@cols;
			
			my $median_row = median( @rows );
			my $median_col = median( @cols );
			
			%convert = (
				$window_on_empty => $median_on_empty,
				$window_on_recurrence => $median_on_recurrence,
				0 => $median_on_empty,
				1 => $median_on_recurrence,
			);
			
			$data[ $median_row ][ $median_col ] = 
				$convert{ $data[ $median_row ][ $median_col ] };
			
			$debug and print "(rows:@rows|cols:@cols)"
				. "[median_row:$median_row][median_col:$median_col]\n";
			
			push @UDLR, [ $U, $median_row - 1, $L, $median_col - 1 ],
						[ $median_row + 1, $D, $median_col + 1, $R ];
			
			push @coords, [ $median_row, $median_col ];
			
			if( $make_gif ){
				push @{ $gif[ $i ] }, [ @{ $_ } ] for reverse @data;
			}
			
			$i ++;
		}
		
		@coords = sort { $a->[ 0 ] <=> $b->[ 0 ] } @coords;
	}
	
	@data = reverse @data;

	if( $to_pgm ){
		my %convert = (
			0 => 255,
			1 => 170,
			$window_on_empty => 200,
			$window_on_recurrence => 140,
			$median_on_empty => 220,
			$median_on_recurrence => 0,
		);
		for( @data ){
			map { $_ = $convert{ $_ } } @{$_};
		}
		for my $gif ( @gif ){
			for( @{ $gif } ){
				map { $_ = $convert{ $_ } } @{ $_ };
				}
			}
	}
	
	if( $to_ppm ){
		my %convert = (
			0 => '255 255 255',
			1 => '170 170 170',
			$window_on_empty => '150 200 200',
			$window_on_recurrence => '100 140 140',
			$median_on_empty => '0 255 255',
			$median_on_recurrence => '0 0 0',
		);
		for( @data ){
			map { $_ = $convert{ $_ } } @{$_};
		}
		for my $gif ( @gif ){
			for( @{ $gif } ){
				map { $_ = $convert{ $_ } } @{ $_ };
				}
			}
	}
	
	if( $to_pbm ){  # not relevant
		print "P1\n";
		print $cols, ' ', $rows, "\n";
	}
	
	if( $to_pgm ){
		print "P2\n";
		print $cols, ' ', $rows, "\n";
		print 255, "\n";
	}
	
	if( $to_ppm ){
		print "P3\n";
		print $cols, ' ', $rows, "\n";
		print 255, "\n";
	}
	
	if( $to_pgm or $to_ppm ){
		print do { local $" = $join; "@{$_}\n" } for @data;
	}
	else{
		print map "[$_]", join ',', map "($_)", 
			map { join ',', map $_ + 1, @{$_} } @coords;
		print "\n";
	}
	
	if( $make_gif ){
		my $i = 0;
		for my $gif ( @gif ){
			my $filename = "gif_" . ( sprintf "%02d", $i ++ ) . 
				( $to_pgm ? ".pgm" : "" ) . ( $to_ppm ? ".ppm" : "" );
			open my $out, '>', $filename or die "$0: Can't create $filename!\n";
			print $out ( $to_pgm ? "P2\n" : "" ) . ( $to_ppm ? "P3\n" : "" );
			print $out $cols, ' ', $rows, "\n";
			print $out 255, "\n";
			print $out do { local $" = $join; "@{$_}\n" } for @{ $gif };
			close $out;
			}
		}
}

sub median {
	my $ref = \@_;
	my @arr = sort { $a <=> $b } @{ $ref };
	
	my $median = @arr % 2 ? $arr[ @arr / 2 ] 
		: ( $arr[ @arr / 2 - 1 ] + $arr[ @arr / 2 ] ) >> 1;
	
	$median;
	}
