#!/usr/bin/perl
use strict;
use Test;

our @samples;
BEGIN {
	open(SAMPLES, "samples") || die "samples: $!";
	@samples=grep { ! /^#/ } <SAMPLES>;
	plan tests => ($#samples + 2);
}

use Lingua::EN::Words2Nums;

ok(! defined words2nums(""));

foreach (@samples) {
	chomp $_;
	my ($num, $text)=split(' ', $_, 2);
	ok(words2nums($text), $num);
}
