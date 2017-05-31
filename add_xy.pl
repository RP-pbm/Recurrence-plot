#!/usr/bin/perl

use strict;
use warnings;

$\ = $/;

my @data = map { [ split ] } <>;

print 0 + @{ $data[0] }, ' ', 0 + @data;

print join ' ', @{$_} for @data;
