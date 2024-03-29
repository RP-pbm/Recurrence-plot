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
my $ARP = 1;
my $CRP = 0;
my $diff = 1;
my $ratio = 0;
my $norm = 1; # Manhattan
my $row_number_to_compare = 0;
my $diff_unvalue_zeroes = 0;
my $Morisita_Horn = 0;
my $Simpson = 0;
my $my_overlap = 0;
my $Jaccard = 0;
my $Sorensen = 0;
my $PCM = 0; # poly-cohort matrix
my $embedding = 1;

for( @opt ){
	/-CRP/i and do {
		$CRP = 1;
		$ARP = 0;
	};
	/-A?RP/i and do {
		$ARP = 1;
		$CRP = 0;
	};
	/-emb(?:edding)?(\d+)/ and do {
		$embedding = $1;
	};
	/-norm(\d+)/ and do {
		$norm = $1;
	};
	/-diff/ and do {
		$Morisita_Horn = 0;
		$ratio = 0;
		$diff = 1;
	};
	/-ratio/ and do {
		$Morisita_Horn = 0;
		$diff = 0;
		$ratio = 1;
	};
	/-row-number(?:-to-compare)?(\d+)/ and do {
		$row_number_to_compare = $1;
	};
	/-diff-unvalue-zeroes/ and do {
		$diff_unvalue_zeroes = 1;
	};
	/-M(?:orisita)?-?H(?:orn)?/i and do {
		$Morisita_Horn = 1;
		$diff = 0;
		$ratio = 0;
	};
	/-simpson/i and do {
		$Simpson = 1;
	};
	/-my-overlap/i and do {
		$Morisita_Horn = 0;
		$diff = 0;
		$ratio = 0;
		$my_overlap = 1;
	};
	/-Jaccard/i and do {
		$Morisita_Horn = 0;
		$diff = 0;
		$ratio = 0;
		$Jaccard = 1;
	};
	/-Sorensen/i and do {
		$Morisita_Horn = 0;
		$diff = 0;
		$ratio = 0;
		$Sorensen = 1;
	};
	/-PCM/i and do {
		$Morisita_Horn = 0;
		$diff = 0;
		$ratio = 0;
		$PCM = 1;
	};
	/-F(\S+)/ and do {
		$split = $1;
	};
	/-toF(\S+)/ and do {
		$join = $1;
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

if( $CRP and @FILES % 2 != 0 ){
	die "\@FILES % 2 != 0; There must be even number of data files to compare (CRP).\n";
	}

$debug and print "\@FILES: @FILES\n";

while( @FILES ){
	my( $file_1, $file_2 ) = $CRP ? ( shift @FILES, shift @FILES ) : ( shift @FILES ) x 2;
	open my $in0, '<', $file_1 or die "$0: can't open $file_1\n";
	open my $in1, '<', $file_2 or die "$0: can't open $file_2\n";
	my @data;
	push @data, [ map { chomp; [ split $split ] } 
		grep m/./, <$_> ] for $in0, $in1;
		
	my @cols;
	my @rows;
	
	for my $file ( 0 .. 1 ){
		( $cols[$file], $rows[$file] ) = 
			( ~~ @{ $data[$file][0] }, ~~ @{ $data[$file] } );
		$debug and print "cols: $cols[$file], rows: $rows[$file]\n";
	}
	
	if( $rows[0] != $rows[1] ){
		die "Number of rows (dimensions) must be equal!\n";
		}
	
	my $rows = $rows[0];
	
	for my $file ( 0 .. 1 ){
		$debug and print "@{$_}\n" for @{ $data[$file] };
	}
	
	if( !$Morisita_Horn && !$diff && !$ratio && !$my_overlap && !$Jaccard &&!$Sorensen && !$PCM ){
		die "No comparison method defined!\n";
		}
	
	if( $PCM and $CRP ){
		die "PCM (poly-cohort matrix) is only for single series!\n";
		}
	
	my @Xi;
	my @lambda_i;
	my @sums;
	
	#--BEGIN: prepare Morisita-Horn
	if( $Morisita_Horn or $my_overlap ){
		
		for my $file ( 0 .. 1 ){
			for my $i ( 1 .. $cols[ $file ] ){
				my $sum;
				for my $j ( 1 .. $rows ){
					$sum += $data[ $file ][ $j - 1 ][ $i - 1 ];
					$debug and print "  $i $j: $sum";
				}
				push @{ $Xi[ $file ] }, $sum;
			}
		}
		
		for my $file ( 0 .. 1 ){
			for my $i ( 1 .. $cols[ $file ] ){
				my $sum = 0;
				for my $j ( 1 .. $rows ){
					( $Xi[ $file ][ $i - 1 ] * ( $Xi[ $file ][ $i - 1 ] - $Simpson ) ) or next;
					$sum += ( $data[ $file ][ $j - 1 ][ $i - 1 ] * 
							( $data[ $file ][ $j - 1 ][ $i - 1 ] - $Simpson ) ) /
						( $Xi[ $file ][ $i - 1 ] * ( $Xi[ $file ][ $i - 1 ] - $Simpson ) );
				}
				$debug and printf "    lambda_i_${file} [%d]: %s\n", $i, $sum;
				push @{ $lambda_i[$file] }, $sum;
			}
		}
		
		$debug and print "\@lambda_i_${_}: @{ $lambda_i[$_] }\n" for 0 .. 1;
		
		for my $i ( 1 .. $cols[ 0 ] ){
			for my $j ( 1 .. $cols[ 1 ] ){
				my $sum;
				for my $r ( 0 .. $rows - 1 ){
					$sum += $data[ 0 ][ $r ][ $i - 1 ] * $data[ 1 ][ $r ][ $j - 1 ];
					$debug and print 
						"[$i:$data[ 0 ][ $r ][ $i - 1 ] * $j:$data[ 1 ][ $r ][ $j - 1 ]]\n";
					$sums[ $i - 1 ][ $j - 1 ] = $sum;
				}
			}
		}
	
	}
	#--END: prepare Morisita-Horn
	
	my @matrix;
	
	for my $i ( 1 .. $cols[ 0 ] ){
		my @line;
		for my $j ( 1 .. $cols[ 1 ] ){
			push @line, do {
				if( $my_overlap ){
					my $sum = 0;
					for my $r ( 0 .. $rows - 1 ){
						next if $Xi[ 0 ][ $i - 1 ] == 0;
						next if $Xi[ 1 ][ $j - 1 ] == 0;
						$sum += 
							( sort { $a <=> $b } 
								$data[ 0 ][ $r ][ $i - 1 ] / $Xi[ 0 ][ $i - 1 ],
								$data[ 1 ][ $r ][ $j - 1 ] / $Xi[ 1 ][ $j - 1 ],
								)[ 0 ];
						}
					1 - $sum;
					}
				elsif( $Morisita_Horn ){
					1 - (
					$Xi[ 0 ][ $i - 1 ] == 0 || $Xi[ 1 ][ $j - 1 ] == 0 ?
						0
					:
						2 * $sums[ $i - 1 ][ $j - 1 ] / 
						( ( $lambda_i[ 0 ][ $i - 1 ] + $lambda_i[ 1 ][ $j - 1 ] ) 
							* $Xi[ 0 ][ $i - 1 ] * $Xi[ 1 ][ $j - 1 ] )
						)
					}
				elsif( $Jaccard ){
					my $Jaccard_ij = 0;
					
					my @row_numbers_to_compare = 1 .. @{ $data[ 0 ] };
					
					my $union = 0;
					my $intersection = 0;
					
					for my $row_number ( @row_numbers_to_compare ){
						$union += ( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] == 1 ||
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] == 1
							);
						$intersection += ( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] == 1 &&
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] == 1
							);
						
						die "Non 0-1 values found in Jaccard!\n" if ( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] != 0 &&
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] != 1 
							or
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] != 0 &&
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] != 1 
							);
						}
					
					if( $diff_unvalue_zeroes ){
						$Jaccard_ij = $union ? $intersection / $union : 0;
						}
					else{
						$Jaccard_ij = $union ? $intersection / $union : 1;
						}
					
					1 - $Jaccard_ij;
					}
				elsif( $Sorensen ){
					my $Sorensen_ij = 0;
					
					my @row_numbers_to_compare = 1 .. @{ $data[ 0 ] };
					
					my $sum = 0;
					my $intersection = 0;
					
					for my $row_number ( @row_numbers_to_compare ){
						$sum += ( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] +
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ]
							);
						$intersection += ( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] == 1 &&
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] == 1
							);
						
						die "Non 0-1 values found in Sorensen!\n" if ( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] != 0 &&
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] != 1 
							or
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] != 0 &&
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] != 1 
							);
						}
					
					if( $diff_unvalue_zeroes ){
						$Sorensen_ij = $sum ? 2 * $intersection / $sum : 0;
						}
					else{
						$Sorensen_ij = $sum ? 2 * $intersection / $sum : 1;
						}
					
					1 - $Sorensen_ij; # Note it does not satisfy the triangle inequality.
					}
				elsif( $PCM ){
					my $PCM_ij = 0;
					
					my @row_numbers_to_compare = 1 .. @{ $data[ 0 ] };
					
					my $union = 0;
					my $poly_cohort = 0;
					
					my $poly_cohort_index;
					
					if( $j > $i ){
						$poly_cohort_index = $j;
						}
					elsif( $i > $j ){
						$poly_cohort_index = $j;
						}
					else{
						$poly_cohort_index = $j;
						}
					
					for my $row_number ( @row_numbers_to_compare ){
						if( $data[ 0 ][ $row_number - 1 ][ 
								$poly_cohort_index - 1 ] == 1 ){
							$union ++;
							$poly_cohort += (
								$data[ 0 ][ $row_number - 1 ][ $i - 1 ] == 1 
								);
							}
						
						die "Non 0-1 values found in PCM!\n" if ( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] != 0 &&
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] != 1 
							or
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] != 0 &&
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ] != 1 
							);
						}
					
					if( $diff_unvalue_zeroes ){
						$PCM_ij = $union ? $poly_cohort / $union : 0;
						}
					else{
						$PCM_ij = $union ? $poly_cohort / $union : 1;
						}
					
					1 - $PCM_ij;
					}
				elsif( $diff ){
					my $diff_ij = 0;
					
					my @row_numbers_to_compare = 1 .. @{ $data[ 0 ] };
					
					if( $row_number_to_compare ){
						@row_numbers_to_compare = $row_number_to_compare;
						}
					
					for my $row_number ( @row_numbers_to_compare ){
						my $diff_row_ij = abs( 
							$data[ 0 ][ $row_number - 1 ][ $i - 1 ] - 
							$data[ 1 ][ $row_number - 1 ][ $j - 1 ]
							);
						if( $diff_unvalue_zeroes ){
							if( 0 == $data[ 0 ][ $row_number - 1 ][ $i - 1 ] && 
								0 == $data[ 1 ][ $row_number - 1 ][ $j - 1 ]
								){
								$diff_row_ij = 1e6;
								}
							elsif( 0 == $data[ 0 ][ $row_number - 1 ][ $i - 1 ] ){
								$diff_row_ij = 1e5;
								}
							elsif( 0 == $data[ 1 ][ $row_number - 1 ][ $j - 1 ] ){
								$diff_row_ij = 1e5;
								}
							}
						
						$diff_ij += $diff_row_ij;
						}
					
					$diff_ij;
					}
				elsif( $ratio ){
					my $ratio_ij;
					if( 0 == $data[ 0 ][ $row_number_to_compare - 1 ][ $i - 1 ] || 
						0 == $data[ 1 ][ $row_number_to_compare - 1 ][ $j - 1 ] ){
						$ratio_ij = 1e6;
						}
					else{
						$ratio_ij = 
							$data[ 0 ][ $row_number_to_compare - 1 ][ $i - 1 ] /
							$data[ 1 ][ $row_number_to_compare - 1 ][ $j - 1 ];
						if( $ratio_ij < 1 ){
							$ratio_ij **= -1;
							}
						$ratio_ij -= 1;
						}
					$ratio_ij;
					}
				else{
					die "[?]";
					}
				};
		}
		push @matrix, [ @line ];
	}
	
	if( $embedding > 1 ){
		
		for my $i ( 1 .. $cols[ 0 ] - $embedding + 1 ){
			for my $j ( 1 .. $cols[ 1 ] - $embedding + 1 ){
				my $value = 0;
				for my $m ( 1 .. $embedding ){
					$value += ( $matrix[ $i - 1 + $m - 1 ][ $j - 1 + $m - 1 ] ) ** $norm;
					}
				$value **= ( 1 / $norm );
				$matrix[ $i - 1 ][ $j - 1 ] = $value;
			}
		}
			
		pop @matrix for 2 .. $embedding;
		splice @{ $_ }, -$embedding + 1 for @matrix;
	}
	
	print map "$_\n", join $join, @{$_} for @matrix;

}

