#!/usr/local/bin/perl
# -*- perl -*-

#
# $Id: test.pl,v 1.4 1999/06/05 00:53:33 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1997 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: <URL:mailto:eserte@cs.tu-berlin.de>
# WWW:  <URL:http://www.cs.tu-berlin.de/~eserte/>
#

use Netscape::Cache;
use Config;
use strict;

$^W = 1;

my %args;
if (@ARGV) {
    $args{-cachedir} = $ARGV[0];
}
my $cache = new Netscape::Cache %args;
if (!$cache) {
    die <<'EOF';
Please start test.pl manually with
    perl -Mblib test.pl /path/to/my/cachedir
EOF
}

my($o, @url);
while ($o = $cache->next_object) {
    push(@url, $o);
}
# sort by name
@url = sort {$a->{'URL'} cmp $b->{'URL'}} @url;

if ($Netscape::Cache::OS_Type eq 'win') {
    open(OUT, ">&STDOUT");
} else {
    my $pager = $Config{'pager'} || 'more';
    open(OUT, "|$pager");
}
print OUT "Object oriented interface:\n";
foreach (@url) {
    print OUT $_->{'URL'}, " ", scalar localtime $_->{'LAST_VISITED'}, "\n";
}

my %tie;
tie %tie, 'Netscape::Cache';
print OUT "Tiehash interface:\n";
my $url;
while(($url, $o) = each %tie) {
    print OUT "$url => $o->{CACHEFILE}\n";
}

close OUT;

exit 0;
