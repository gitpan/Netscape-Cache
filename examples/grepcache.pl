#!/usr/local/bin/perl
# -*- perl -*-

#
# $Id: grepcache.pl,v 1.1 1997/03/28 13:01:35 eserte Exp $
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

$c = new Netscape::Cache;

$urlrx = shift || die "Argument 'url regexp' missing";

while(defined($o = $c->next_object)) {
    if ($o->{'URL'} =~ /$urlrx/o) {
	print $o->{'URL'} . ": " . $o->{'CACHEFILE'}, "\n";
    }
}
