#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @FILES;
my @opt;

for( @ARGV ){
	/^-\S/ ? ( push @opt, $_ ) : ( push @FILES, $_ );
}

my $tests_DIR = 'tests';
my $outputs_DIR = 'outputs';

my $to_test = 1;
my $make_outputs = 0;
my $remove_outputs = 0;
my $make_diffs = 0;
my $remove_diffs = 0;
my $all = 0;

for( @opt ){
	/-all/ and do {
		$all = 1;
	};
	/-outputs|-outs|-out/ and do {
		$make_outputs = 1;
		$to_test = 0;
	};
	/-rmoutputs|-rmouts|-rmout/ and do {
		$remove_outputs = 1;
		$remove_diffs = 1;
		$to_test = 0;
	};
	/-diffs?/ and do {
		$make_diffs = 1;
		$to_test = 1;
	};
	/-rmdiffs?/ and do {
		$remove_diffs = 1;
	};
	/-d$/ and $debug = 1;
}

if( not @FILES or $all ){
	@FILES = map s/\s//gr, grep /^\S+\.pl$/, `ls`;
	}

for( @FILES ){
	print "Testing '$_':\n";
	open my $script, '<', $_ or die "$0: Can't open script.\n";
	
	my $script_name = s/\.pl$//r;
	
	my @tests = grep length, 
		map { /^${script_name}-(\d{3})\.tst$/ ? $1 : '' } `ls ${tests_DIR}/`;
	
	for my $test ( @tests ){
		$debug and print $test . "\n";
		
		my $opt = '';
		my $opt_name = "${tests_DIR}/${script_name}-${test}.opt";
		if( -e $opt_name ){
			$debug and print "OPT\n";
			open my $opt_fh, '<', $opt_name or die "$0: Can't open.\n";
			$opt = <$opt_fh> // '';
			chomp $opt;
			close $opt_fh;
			}
		
		print "<./${_} ${opt} ${tests_DIR}/${script_name}-${test}.tst 2>&1>\n";
		my $output = `./${_} ${opt} ${tests_DIR}/${script_name}-${test}.tst 2>&1`;
		$debug and print $output;
		
		if( $make_outputs ){
			open my $out, '>', "${outputs_DIR}/${script_name}-${test}.out"
				or die "$0: Can't create and write.\n";
			print {$out} $output;
			}
		
		if( $remove_outputs ){
			`rm ${outputs_DIR}/${script_name}-${test}.out`;
			}
			
		if( $remove_diffs ){
			`rm ${outputs_DIR}/${script_name}-${test}.diff`;
			}
		
		if( $to_test ){
			my $tmp_out_name = "${outputs_DIR}/${script_name}-${test}.out.tmp";
			open my $tmp_out, '>', $tmp_out_name
				or die "$0: Can't create and write.\n";
			print {$tmp_out} $output;
			
			my $diff = `diff $tmp_out_name ${outputs_DIR}/${script_name}-${test}.out`;
				$debug and print "[$diff]\n";
				
			print "$test: ";
			if( length $diff ){
				print "DIFF:\n${diff}\n";
				}
			else{
				print "OK\n";	
				}
		
			close $tmp_out;
			`rm $tmp_out_name`;
			
			if( $make_diffs and -e "${outputs_DIR}/${script_name}-${test}.out" ){
				open my $diffs, '>', "${outputs_DIR}/${script_name}-${test}.diff"
					or die "$0: Can't create and write.\n";
				print {$diffs} $diff;
				}
			}
			
		}
	
}
