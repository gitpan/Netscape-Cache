#!/usr/local/bin/perl
# -*- perl -*-

#
# $Id: grepcache.pl,v 1.2 1997/08/19 10:02:52 eserte Exp $
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

for($i = 0; $i<=$#ARGV; $i++) {
    if ($ARGV[$i] eq '-i') {
	$case_insens = 1;
    } elsif ($ARGV[$i] eq '-r') {
	$reverse = 1;
    } elsif ($ARGV[$i] =~ /^-/) {
	die "Wrong argument. Usage: grepcache.pl [-i] [-r] pattern ...";
    } else {
	push(@urlrx, $ARGV[$i]);
    }
}

if (@urlrx == 0) {
    die "Argument 'url regexp' missing";
}
 
if (!$reverse) {
    $urlrx = join("|", @urlrx);
    if ($case_insens) {
	$urlrx = "(?i)$urlrx";
    }
    while(defined($url = $c->next_url)) {
	if ($url =~ /$urlrx/o) {
	    $o = $c->get_object($url);
	    if (!defined $o) {
		warn "Can't get object for <$url>";
	    } else {
		print $o->{'URL'} . ": " . $o->{'CACHEFILE'}, "\n";
	    }
	}
    }
} else {
    foreach $urlrx (@urlrx) {
	$url = $c->get_url_by_cachefile($urlrx);
	if (defined $url) {
	    print "$url: $urlrx\n";
	}
    }
}

## another way to do the while loop, less efficient
# while(defined($o = $c->next_object)) {
#     if ($o->{'URL'} =~ /$urlrx/o) {
# 	print $o->{'URL'} . ": " . $o->{'CACHEFILE'}, "\n";
#     }
# }
