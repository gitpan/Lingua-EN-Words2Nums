#!/usr/bin/perl
use strict;
use Test;

our @samples;
BEGIN {
	open(SAMPLES, "samples") || die "samples: $!";
	@samples=grep { ! /^#/ } <SAMPLES>;
	plan tests => (scalar @samples);
}

use Lingua::EN::Words2Nums;

foreach (@samples) {
	chomp $_;
	my ($num, $text)=split(' ', $_, 2);
	if ($num eq 'undef') {
		ok(! defined words2nums($text));
	}
	else {
		ok(words2nums($text), $num);
	}
}
