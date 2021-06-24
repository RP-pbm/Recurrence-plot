#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;
my $debug2 = 0;

my @FILES;
my @opt;

for( @ARGV ){
	/^-\S/ ? ( push @opt, $_ ) : ( push @FILES, $_ );
}

my $step = 0.1;
my $expand;
my $ARP = 1;
my $CRP = 0;
my $pbm = 0;
my $to_pbm = 0;
my $to_pgm = 0;
my $max_value;

my $split = " ";
my $join = " ";

for( @opt ){
	/-step(\S+)/ and do {
		$step = $1;
	};
	/-pbm/ and do {
		$pbm = 1;
	};
	/-topbm/ and do {
		$to_pbm = 1;
	};
	/-topgm/ and do {
		$to_pgm = 1;
	};
	/-max-value(\d+)/ and do {
		$max_value = $1;
	};
	/-CRP/i and do {
		$CRP = 1;
		$ARP = 0;
	};
	/-A?RP/i and do {
		$ARP = 1;
		$CRP = 0;
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

if( $CRP and @FILES != 3 ){
	die "\@FILES != 3; There must be 3 data files to expand CRP.\n";
	}

$debug and print "\@FILES: @FILES\n";

$expand = 1 / $step;

for( 1 ){
	my @axes;
	if( 1 ){
		my $file_name = shift @FILES;
		my $in_axis_x;
		open $in_axis_x, '<', $file_name or die "$0: [$file_name] ... : $!\n";
		push @axes, map { chomp; [ split $split, $_, -1 ] } <$in_axis_x>;
		push @axes, [ @{ $axes[ 0 ] } ];
		}
	if( $CRP ){
		my $file_name = shift @FILES;
		my $in_axis_y;
		open $in_axis_y, '<', $file_name or die "$0: [$file_name] ... : $!\n";
		pop @axes;
		push @axes, map { chomp; [ split $split, $_, -1 ] } <$in_axis_y>;
		}
	chomp @axes;
	
	$debug and print "[@{ $_ }]\n" for @axes;
	
	my $file_name = shift @FILES;
	my $in;
	open $in, '<', $file_name or die "$0: [$file_name] ... : $!\n";
	
	my @data = grep m/./, <$in>;
	chomp @data;
	
	my( $cols, $rows );
	
	if( $pbm ){
		shift @data;
		( $cols, $rows) = split ' ', shift @data;
		}
	else{
		$cols = split $split, $data[ 0 ];
		$rows = 0 + @data;
		}
	
	@data = map { [ split $split, $_, -1 ] } @data;
	
	if( $cols != @{ $axes[ 0 ] } ){
		die "\$cols ($cols) != length of axis x (" . 1 * @{ $axes[ 0 ] } . ")!\n";
		}
	if( $rows != @{ $axes[ 1 ] } ){
		die "\$rows ($rows) != length of axis y (" . 1 * @{ $axes[ 1 ] } . ")!\n";
		}
	
	if( $to_pgm ){
		color_even( \@data, $cols, $rows, $max_value );
		}
	
	my $pattern = generate_pattern( \@{ $axes[ 0 ] }, $step, $expand );
	
	my @new;
	push @new, [ ] for 1 .. $rows;
	
	my @x_points;
	my $x_point_length = 3;
	push @x_points, [ ] for 1 .. $x_point_length;
	
	my $new_cols = 0;
	
	expand_by_pattern( $pattern, \@data, \@new, $cols, $rows, \$new_cols );
	$cols = $new_cols;
	$new_cols = 0;
	
	print STDERR "cols:[$cols], rows:[$rows]\n";
	
	transpose( \@new, $cols, $rows );	
	( $cols, $rows ) = reverse( $cols, $rows );
	
	print STDERR "cols:[$cols], rows:[$rows]\n";
	
	my @new2;
	push @new2, [ ] for 1 .. $rows;
	
	expand_by_pattern( $pattern, \@new, \@new2, $cols, $rows, \$new_cols );
	$cols = $new_cols;
	
	print STDERR "cols:[$cols], rows:[$rows]\n";
	
	transpose( \@new2, $cols, $rows );	
	( $cols, $rows ) = reverse( $cols, $rows );
	
	print STDERR "cols:[$cols], rows:[$rows]\n";
	
#	expanding_by_steps( \@axes, \@data, \@new, $cols, $rows, $to_pgm, \$new_cols );
	
	if( $to_pbm ){
		print "P1\n";
		print "$cols $rows\n";
		}
	
	if( $to_pgm){
		print "P2\n";
		print "$cols $rows\n";
		print "$max_value\n";
		}
		
	print do { local $" = $join; "@{$_}" }, "\n" for @new2;
}

sub expanding_by_steps {
	my( $ref_axes, $ref_data, $ref_new, $cols, $rows, $to_pgm, $ref_new_cols ) = @_;
	
	my $prev = ( $ref_axes->[ 0 ][ 1 ] - $ref_axes->[ 0 ][ 0 ] ) / 2;
	$debug and print $prev . $/;
	
	for my $i ( 0 .. $cols - 2 ){
		$debug and print '-' x 10 . $/;
		$debug and print "$ref_axes->[ 0 ][ $i + 0 ] $ref_axes->[ 0 ][ $i + 1 ]\n";
		my $avg = ( $ref_axes->[ 0 ][ $i + 1 ] - $ref_axes->[ 0 ][ $i ] ) / 2;
		$debug and print "prev :$prev\n";
		$debug and print "avg  :$avg\n";
		my $width = $prev + $step * int $avg / $step;
		$debug and print "width:" . $width . $/;
		my $times = $width / $step;
		$debug and print "times:" . $times . $/;
		${ $ref_new_cols } += $times;
		
		for my $row ( 0 .. $rows - 1 ){
			for( 1 .. $times ){
				push @{ $ref_new->[ $row ] }, !$to_pgm ? $ref_data->[ $row ][ $i ] :
					( 1 - $ref_data->[ $row ][ $i ] ) * 2 + $i % 2;
				
			#	next if $row >= $x_point_length;	
			#	push @{ $x_points[ $row ] }, 
				}
			}
		
		$prev = $step * ( ( int $avg / $step ) + 1 * ( $avg / $step ) =~ /\./ );
		}
	}

sub generate_pattern {
	my( $ref_axis, $step, $expand ) = @_;
	
	my @A = @{ $ref_axis };
	
	my $A = join ' ', @A;
	
	my $num = '-?\d+(?:\.\d+)?';
	
	my @XO = qw( X O );
	
	my $i = 0;
	
	my $new = '';
	
	my $fail = 0;
	
	my $eps = 0.00001;
	
	$A =~ /
		( $num )[ ]
		(?=
			( $num )
		)
		(?{
			$new .= $XO[ $i ];
			my $diff = $2 * $expand - $1 * $expand;
			$diff += $eps;
			$fail ||= $diff - int $diff > $eps * 2;
			$debug and print "[$1],[$2],diff:[$diff]\n";
			$new .= '-' x ( $diff - 1 );
			$i = 1 - $i;
			})
		(*SKIP)(*FAIL)
		/x;
	
	$new .= $XO[ $i ]; 
	
	$fail and die "Some axes values are not matched on steps.\n";
	
	$debug and print "new:[$new]\n";
	
	for( 1 .. 2 ){
		$new =~ s/[@XO](-+)/$1$&/;
		$new =~ s/\G-\K-//g;
		$new = reverse $new;
		}
	
	$debug and print "new:[$new]\n";
	
	1 while $new =~ s/([@XO])-(-*)-([@XO])/
		$1 . ( lc $1 ) . $2 . ( lc $3 ) . $3 /gie;
	1 while $new =~ s/([@XO])-([@XO])/ $1 . ( lc $1 ) . $2 /gie;
	1 while $new =~ s/-([@XO])/ ( lc $1 ) . $1 /gie;
	1 while $new =~ s/([@XO])-/ $1 . ( lc $1 ) /gie;
	
	$debug and print "new:[$new]\n";
	
	$new;
	}

sub expand_by_pattern {
	my( $pattern, $ref_data, $ref_new, $cols, $rows, $ref_new_cols ) = @_;
	
	my $prev = '';
	
	my $i = 0;
	
	while( $pattern =~ /(.)\1*/gi ){
		
		my $match = $&;
		$debug and print "match:[$match]\n";
		my $length = length $match;
		
		${ $ref_new_cols } += $length;
		
		for my $row ( 0 .. $rows - 1 ){
			for( 1 .. $length ){
				push @{ $ref_new->[ $row ] }, $ref_data->[ $row ][ $i ];
				}
			}
		
		$i ++;
		}
	}

sub transpose {
	my( $ref_new, $cols, $rows ) = @_;
	
	my @A;
	
	for my $row ( 0 .. $rows - 1 ){
		for my $col ( 0 .. $cols - 1 ){
			$A[ $col ][ $row ] = $ref_new->[ $row ][ $col ];
			}
		}
	
	@{ $ref_new } = ();
	
	push @{ $ref_new }, [ @{ $_ } ] for @A;
	}

sub color_even {
	my( $ref_data, $cols, $rows, $max_value ) = @_;
	
	for my $row ( 0 .. $rows - 1 ){
		for my $col ( 0 .. $cols - 1 ){
			$ref_data->[ $row ][ $col ] = 1 - $ref_data->[ $row ][ $col ];
			$ref_data->[ $row ][ $col ] *= $max_value;
			if( $row % 2 == 1 or $col % 2 == 1 ){
				$ref_data->[ $row ][ $col ] += 0.5 <=>
				$ref_data->[ $row ][ $col ];
				}
			}
		}
	}
;
;
;
;
;
;
;
;
;
;
;
;
;
;