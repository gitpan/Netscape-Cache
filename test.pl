#!/usr/local/bin/perl
# -*- perl -*-

#
# $Id: oo.t,v 1.2 1997/03/29 19:32:23 eserte Exp eserte $
# Author: Slaven Rezic
#
# Copyright © 1997 Slaven Rezic. All rights reserved.
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

my $cache = new Netscape::Cache;
die if !$cache;

my($o, @url);
while ($o = $cache->next_object) {
    push(@url, $o);
}
# sort by name
@url = sort {$a->{'URL'} cmp $b->{'URL'}} @url;

my $pager = $Config{'pager'} || 'more';
open(OUT, "|$pager");
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
