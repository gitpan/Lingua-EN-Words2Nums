#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Lingua::EN::Words2Nums',
	VERSION   => getversion(),
	PM_FILTER => 'grep -v \\"NOT IN PRODUCTION CODE\\"'
);

# The version is pulled from the debian changelog, to avoid having to keep
# two copies synced.
sub getversion {
	open(DCH, "debian/changelog") or die "debian/changelog: $!";
	$_=<DCH>;
	my ($vers) = m/\((.+)\)/;
	die "no version" unless length $vers;
	return $vers;
}

