#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: delcache.pl,v 1.1 1997/10/29 11:15:10 eserte Exp $
# Author: Slaven Rezic
#
# Copyright © 1997 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Netscape::Cache;

$c = new Netscape::Cache;

for($i = 0; $i<=$#ARGV; $i++) {
    if ($ARGV[$i] eq '-i') {
	$case_insens = 1;
    } elsif ($ARGV[$i] =~ /^-/) {
	die "Wrong argument. Usage: delcache.pl [-i] pattern ...";
    } else {
	push(@urlrx, $ARGV[$i]);
    }
}

if (@urlrx == 0) {
    die "Argument 'url regexp' missing";
}
 
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
	    push(@del_list, $o);
	}
    }
}

foreach (@del_list) {
    print STDERR $_->{'URL'}, "\n";
    $c->delete_object($_);
}
