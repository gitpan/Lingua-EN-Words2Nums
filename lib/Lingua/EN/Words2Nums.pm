#!/usr/bin/perl

=head1 NAME

Lingua::EN::Words2Nums - convert English text to numbers

=cut

package Lingua::EN::Words2Nums;
#use warnings;
#use strict;
require Exporter;
our @ISA=qw(Exporter);
our @EXPORT=qw(&words2nums);

=head1 SYNOPSIS

 use Lingua::EN::Words2Nums;
 $num=words2nums("one thousand and one");
 $num=words2nums("twenty-second");
 $num=words2nums("15 billion, 6 million, and ninteen");

=head1 DESCRIPTION

This module converts English text into numbers. It supports both ordinal and
cardinal numbers, negative numbers, and numbers larger than one billion.

The main subroutine, which is exported by default, is words2nums(). This
subroutine, when fed a string, will attempt to convert it into a number.
If it succeeds, the number will be returned. If it fails, it returns undef.

=head1 VARIABLES

There are a number of variables that can be used to tweak the behavior of this
module. For example, debugging can be be enabled by setting
$Lingua::EN::Words2Nums::debug=1

=over 4

=cut

# Public global variables.
our $debug = 0;
our $billion = 10 ** 9;

=item $Lingua::EN::Words2Nums::debug

Default: 0. If set to a true value, outputs on standard error some useful
messages if parsing fails for some reason.

=item $Lingua::EN::Words2Nums::million

Default: 10 ** 9. This is the number that will be returned for "one million".
It defaults to the American version; the English will want to set it to
10 ** 12.

=back

=head1 NOTES

It does not understand decimals or fractions, yet.

It happens that it can do some simple math such as "fourteen minus five", 
but don't count on that working in the future.

Scores are supported, eg: "four score and ten". So are dozens. So is a baker's
dozen. And a gross.

Various mispellings of numbers are understood.

=cut
 
my ($total, $mult, $oldpre, $newmult, $suffix, $val);

my %nametosub = (
	zero =>		[ \&num, 0 ],
	one =>		[ \&num, 1 ],
	first =>	[ \&num, 1 ],
	two =>		[ \&num, 2 ],
	second =>	[ \&num, 2 ],
	three =>	[ \&num, 3 ],
	third =>	[ \&num, 3 ],
	four =>		[ \&num, 4 ],
	five =>		[ \&num, 5 ],
	six =>		[ \&num, 6 ],
	seven =>	[ \&num, 7 ],
	eight =>	[ \&num, 8 ],
	nine =>		[ \&num, 9 ],
	ten =>		[ \&num, 10 ],
	eleven =>	[ \&num, 11 ],
	twelve =>	[ \&num, 12 ],
	thirteen =>	[ \&num, 13 ],
	fifteen =>	[ \&num, 15 ],
	eighteen =>	[ \&num, 18 ],
	ninteen =>	[ \&num, 19 ], # common(?) mispelling
	teen =>		[ \&suffix, 10 ], # takes care of the regular teens
	twenty =>	[ \&num, 20 ],
	thirty =>	[ \&num, 30 ],
	fourty =>	[ \&num, 40 ],
	fifty =>	[ \&num, 50 ],
	sixty =>	[ \&num, 60 ],
	seventy =>	[ \&num, 70 ],
	eighty =>	[ \&num, 80 ],
	ninety =>	[ \&num, 90 ],
	ninty =>	[ \&num, 90 ], # common mispelling
	hundred =>	[ \&prefix, 100 ],
	thousand => 	[ \&prefix, 1000 ],
	million =>	[ \&prefix, 10 ** 6 ],
	billion => 	[ \&prefix, $billion ],
	negative => 	[ \&invert ],
	minus =>	[ \&invert ],
	score =>	[ \&prefix, 20 ],
	gross => 	[ \&prefix, 12 * 12 ], 
	dozen =>        [ \&prefix, 12 ],
	bakersdozen =>	[ \&prefix, 13 ],
	bakerdozen =>   [ \&prefix, 13 ],
	s => 		[ sub {} ], # ignore 's', at the end of a word, 
	                            # easy pluralization of dozens, etc.
);

# Note the ordering, so that eg, fourty has a chance to match before four.
my $numregexp = join("|", reverse sort keys %nametosub);
$numregexp=qr/($numregexp)/;

sub num ($) {
	$val = shift;
	if ($suffix) {
		$val += $suffix;
		$suffix = 0;
	}
	$total += $val * $mult;
	$newmult = 0;
}

sub prefix ($) {
	my $pre = shift;
	if ($pre > $oldpre) { # end of a prefix chain
		$total += $mult if $newmult; # special case for lone "thousand", etc.
		$mult = 1;
	}
	$mult *= $pre;
	$oldpre = $pre;
	$newmult = 1;
}

sub suffix ($) {
	$suffix = shift;
}

sub invert () {
	$total *= -1;
}

sub failure ($) {
	print STDERR shift()."\n" if $debug;
	return; # undef on failure
}

sub words2nums ($) {
	$_=lc(shift);
	return $_ if /^[-+.0-9]+$/; # short circuit for already valid number

	$total=$oldpre=$suffix=$newmult=0;
	$mult=1;

	return failure("not a number") unless length $_;
	s/th$//; # cardinalize (there are some special cases in the hash too)
	s/\b(and|a)\b//g; # ignore "and", "a".
	s/[^A-Za-z0-9]//g; # ignore punctuation
	# Work backwards up the string.
	while (length $_) {
		$nametosub{$1}[0]->($nametosub{$1}[1]) while s/$numregexp$//;
		if (length $_) {
			if (s/(\d+)$//) {
				num($1);
			}
			else {
				last;
			}
		}
	}
	return failure("error at $_") if length $_;
	$total += $mult if $newmult; # special case for lone "thousand", etc.
	return $total;
}

=head1 AUTHOR

Copyright © 2001 Joey Hess <joey@kitenet.net>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1
