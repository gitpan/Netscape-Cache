#!/usr/local/bin/perl
# -*- perl -*-

#
# $Id: $
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

$cache = new Netscape::Cache;

while ($o = $cache->next_object) {
    push(@url, $o);
}
# sort by name
@url = sort {$a->{'URL'} cmp $b->{'URL'}} @url;

$pager = $Convfig{pager} || more;
open(OUT, "|$pager");
foreach (@url) {
    print OUT $_->{'URL'}, " ", scalar localtime $_->{'LAST_VISITED'}, "\n";
}
close OUT;

