#!/usr/bin/perl

=head1 NAME

Lingua::EN::Words2Nums - convert English text to numbers

=cut

package Lingua::EN::Words2Nums;
use warnings; # NOT IN PRODUCTION CODE
use strict; # NOT IN PRODUCTION CODE
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
cardinal numbers, negative numbers, and very large numbers.

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

=item $Lingua::EN::Words2Nums::billion

Default: 10 ** 9. This is the number that will be returned for "one billion".
It defaults to the American version; the English will want to set it to
10 ** 12. Setting this number automatically changes all the larger numbers
(trillion, quadrillion, etc) to match.

=back

=head1 NOTES

It does not understand decimals or fractions, yet.

It happens that it can do some simple math such as "fourteen minus five", 
but don't count on that working in the future.

Scores are supported, eg: "four score and ten". So are dozens. So is a baker's
dozen. And a gross.

Various mispellings of numbers are understood.

While it handles googol correctly, googolplex is too large to fit in perl's
standard scalar type, and "inf" will be returned.

=cut
 
our %nametosub = (
	naught =>	[ \&num, 0 ],   # Cardinal numbers, leaving out the 
	zero =>		[ \&num, 0 ],	# ones that just add "th".
	one =>		[ \&num, 1 ],	first =>	[ \&num, 1 ],
	two =>		[ \&num, 2 ],	second =>	[ \&num, 2 ],
	three =>	[ \&num, 3 ],	third =>	[ \&num, 3 ],
	four =>		[ \&num, 4 ],	fourth =>	[ \&num, 5 ],
	five =>		[ \&num, 5 ],	fifth =>	[ \&num, 5 ],
	six =>		[ \&num, 6 ],
	seven =>	[ \&num, 7 ],	seven =>	[ \&num, 7 ],
	eight =>	[ \&num, 8 ],   eighth =>	[ \&num, 8 ],
	nine =>		[ \&num, 9 ],	ninth =>	[ \&num, 9 ],
	ten =>		[ \&num, 10 ],
	eleven =>	[ \&num, 11 ],
	twelve =>	[ \&num, 12 ],	twelfth =>	[ \&num, 12 ],
	thirteen =>	[ \&num, 13 ],
	fifteen =>	[ \&num, 15 ],
	eighteen =>	[ \&num, 18 ],
	ninteen =>	[ \&num, 19 ], # common(?) mispelling
	teen =>		[ \&suffix, 10 ], # takes care of the regular teens
	twenty =>	[ \&num, 20 ],	twentieth =>	[ \&num, 20 ],
	thirty =>	[ \&num, 30 ],  thirtieth =>	[ \&num, 30 ],
	fourty =>	[ \&num, 40 ],	fortieth =>	[ \&num, 40 ],
	fifty =>	[ \&num, 50 ],	fiftieth =>	[ \&num, 50 ],
	sixty =>	[ \&num, 60 ],	sixtieth =>	[ \&num, 60 ],
	seventy =>	[ \&num, 70 ],	seventieth =>	[ \&num, 70 ],
	eighty =>	[ \&num, 80 ],	eightieth =>	[ \&num, 80 ],
	ninety =>	[ \&num, 90 ],	ninetieth =>	[ \&num, 90 ],
	ninty =>	[ \&num, 90 ], # common mispelling
	hundred =>	[ \&prefix, 100 ],
	thousand => 	[ \&prefix, 1000 ],
	million =>	[ \&prefix, 10 ** 6 ],
	milion =>	[ \&prefix, 10 ** 6 ], # common(?) mispelling
	milliard =>	[ \&prefix, 10 ** 9 ],
	billion => 	[ \&powprefix, 2 ], # These vary depending on country.
	trillion =>	[ \&powprefix, 3 ],
	quadrillion =>	[ \&powprefix, 4 ],
	quintillion =>	[ \&powprefix, 5 ],
	sextillion =>	[ \&powprefix, 6 ],
	septillion =>	[ \&powprefix, 7 ],
	octillion =>	[ \&powprefix, 8 ],
	nonillion =>	[ \&powprefix, 9 ],
	decillion =>	[ \&powprefix, 10 ],
	googol =>	[ \&googol ],
	googolplex =>	[ \&googolplex ],
	negative => 	[ \&invert ],
	minus =>	[ \&invert ],
	score =>	[ \&prefix, 20 ],
	gross => 	[ \&prefix, 12 * 12 ],
	dozen =>        [ \&prefix, 12 ],
	bakersdozen =>	[ \&prefix, 13 ],
	bakerdozen =>	[ \&prefix, 13 ],
	eleventyone =>	[ \&num, 111 ], # This nprogram written on the day
	eleventyfirst =>[ \&num, 111 ], # FOTR released.
	s => 		[ sub {} ], # ignore 's', at the end of a word, 
	                            # easy pluralization of dozens, etc.
	es =>		[ sub {} ], # same for 'es'; for googolplexes, etc.
	th =>		[ sub {} ], # ignore 'th', for cardinal nums
);

# Note the ordering, so that eg, ninety has a chance to match before nine.
my $numregexp = join("|", reverse sort keys %nametosub);
$numregexp=qr/($numregexp)/;

my ($total, $mult, $oldpre, $newmult, $suffix, $val);

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

sub powprefix {
	my $power = shift;
	if ($billion == 10 ** 9) { # EN
		prefix(10 ** (($power + 1) * 3));
	}
	elsif ($billion == 10 ** 12) { # GB
		prefix(10 ** ($power * 6));
	}
	else {
		failure("\$billion is set to odd value: $billion");
	}
}


sub suffix ($) {
	$suffix = shift;
}

sub invert () {
	$total *= -1;
}

sub googol () {
	prefix(10 ** 100);
}

sub googolplex () {
	prefix(10 ** (10 ** 100));
}

sub failure ($) {
	print STDERR shift()."\n" if $debug;
	return; # undef on failure
}

sub words2nums ($) {
	$_=lc(shift);
	chomp $_;
	return $_ if /^[-+.0-9\s]+$/; # short circuit for already valid number

	$total=$oldpre=$suffix=$newmult=0;
	$mult=1;
	
	s/\b(and|a|of)\b//g; # ignore some common words
	s/[^A-Za-z0-9.]//g; # ignore punctuation, except period.
	return failure("not a number") unless length $_;

	# Work backwards up the string.
	while (length $_) {
		$nametosub{$1}[0]->($nametosub{$1}[1]) while s/$numregexp$//;
		if (length $_) {
			if (s/(\d+)(?:st|nd|rd|th)?$//) {
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
