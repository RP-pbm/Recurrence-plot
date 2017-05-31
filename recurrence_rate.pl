#!/usr/bin/perl

use warnings;
use strict;

my $debug = 0;

my @ARGV_2;
my @opt;

for (@ARGV){
	/^-/ ? (push @opt, $_) : (push @ARGV_2, $_);
}

my $dots = 0;
my $printf = '%f';

for (@opt){
	/-x/ and do {
		$dots = 1;
	};
	/-f(\S+)/ and do {
		$printf = "%$1";
	};
	/-d/ and $debug = 1;
}

@ARGV = @ARGV_2;

for (@ARGV){
	open my $in, '<', $_ or die "$0: [$_] ... : $!\n";
	my $format = <$in>;
	$format =~ /P1/ or die "Not P1\n";
	my @rsl = split ' ', <$in>;
	my $rsl = $rsl[0] * $rsl[1];
	my $data = do { local $/ ; <$in> };
	my $b = () = $data =~ /1/g;
	
	$dots and $printf = "%d";
	printf "${printf}\n", $b / ($dots ? 1 : $rsl );
}
