#!/usr/local/bin/perl
# -*- perl -*-

#
# $Id: test.pl,v 1.1 1997/03/15 15:37:36 eserte Exp $
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

my $cache = new Netscape::Cache;
my($o, @url);
while ($o = $cache->next_object) {
    push(@url, $o);
}
# sort by name
@url = sort {$a->{'URL'} cmp $b->{'URL'}} @url;

my $pager = $Config{'pager'} || 'more';
open(OUT, "|$pager");
foreach (@url) {
    print OUT $_->{'URL'}, " ", scalar localtime $_->{'LAST_VISITED'}, "\n";
}
close OUT;

