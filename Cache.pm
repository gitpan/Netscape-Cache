#!/usr/local/bin/suidperl
# -*- perl -*-

#
# $Id: Cache.pm,v 1.4 1997/03/15 15:37:22 eserte Exp eserte $
# Author: Slaven Rezic
#
# Copyright � 1997 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: <URL:mailto:eserte@cs.tu-berlin.de>
# WWW:  <URL:http://www.cs.tu-berlin.de/~eserte/>
#

=head1 NAME

Netscape::Cache - object class for accessing Netscape cache files

=head1 SYNOPSIS

    use Netscape::Cache;

    $cache = new Netscape::Cache;
    while (defined($url = $cache->next_url)) {
	print $url, "\n";
    }

    while (defined($o = $cache->next_object)) {
	print
	  $o->{'URL'}, "\n",
	  $o->{'CACHEFILE'}, "\n",
	  $o->{'LAST_MODIFIED'}, "\n",
	  $o->{'MIME_TYPE'}, "\n";
    }

=head1 DESCRIPTION

The C<Netscape::Cache> module implements an object class for
accessing the filenames and URLs of the cache files used by the
Netscape web browser. You can access the cached URLs offline via Netscape
if you set C<Options-E<gt>Network Preferences-E<gt>Verify Document>
to C<Never>.

Note: You can also use Netscape's undocumented pseudo-URLs C<about:cache>,
C<about:memory-cache> and C<about:global-history> to access your cache,
memory cache and history.

=cut

package Netscape::Cache;
use DB_File;
use strict;
use vars qw($DEFAULT_CACHE_DIR $DEFAULT_CACHE_INDEX $DEBUG $VERSION);

$DEFAULT_CACHE_DIR   = "$ENV{HOME}/.netscape/cache";
$DEFAULT_CACHE_INDEX = "index.db";
$DEBUG = 2;
$VERSION = '0.22';

=head1 CONSTRUCTOR

    $cache = new Netscape::Cache(-cachedir => "$ENV{HOME}/.netscape/cache");

This creates a new instance of the C<Netscape::Cache> object class. The
I<-cachedir> argument is optional. By default, the cache directory setting
is retrieved from C<~/.netscape/preferences>.

If the Netscape cache index file does not exist, a warning message
will be generated, and the constructor will return C<undef>.

=cut

sub new {
    my($pkg, %a) = @_;
    my $cachedir = $a{-cachedir} || get_cache_dir() || $DEFAULT_CACHE_DIR;
    my $indexfile = "$cachedir/$DEFAULT_CACHE_INDEX";
    $indexfile =~ s|^~/|$ENV{'HOME'}/|;
    if (-f $indexfile) {
	my(%cache, $self);
	tie %cache, 'DB_File', $indexfile;
	$self->{'CACHE'} = \%cache;
	$self->{'CACHEDIR'} = $cachedir;
	$self->{'INDEXFILE'} = $indexfile;	
	bless $self, $pkg;
    } else {
	warn "No cache db found!\n";
        undef;
    }
}

=head1 METHODS

The C<Netscape::Cache> class implements the following methods:

=over

=item *

B<rewind> - reset cache index to first URL

=item *

B<next_url> - get next URL from cache index

=item *

B<next_object> - get next URL as a full B<Netscape::Cache::Object> description
from cache index

=item *

B<get_object> - get the B<Netscape::Cache::Object> description for a given URL

=back

Each of the methods is described separately below.

=head2 next_url

    $url = $history->next_url;

This method returns the next URL from the cache index. Unlike
B<Netscape::History>, this method returns a string and not an
URI::URL-like object.

This method is faster than B<next_object>, since it does only evaluate the
URL of the cached file.

=cut

sub next_url {
    my $self = shift;
    my $url;
    do {
	my $key = each %{ $self->{'CACHE'} };
	return undef if !defined $key;
	$url = Netscape::Cache::Object::url($key);
    } while !$url;
    $url;
}

=head2 next_object

    $cache->next_object;

This method returns the next URL from the cache index as a
B<Netscape::Cache::Object> object. See below for accessing the components
(cache filename, content length, mime type and more) of this object.

=cut

sub next_object {
    my $self = shift;
    my $o;
    do {
	my($key, $value) = each %{ $self->{'CACHE'} };
	return undef if !defined $key;
	$o = Netscape::Cache::Object->new($key, $value);
    } while !defined $o;
    $o;
}

=head2 get_object

    $cache->get_object;

This method returns the B<Netscape::Cache::Object> object for a given URL.
If the URL does not live in the cache index, then the returned value will be
undefined.

=cut

sub get_object {
    my($self, $url) = @_;
    my $key = Netscape::Cache::Object::_make_key_from_url($url);
#      pack("l", length($url)+13) . pack("l", length($url)+1)
#	. $url . ("\000" x 5);
    my $value = $self->{'CACHE'}->{$key};
    $value ? new Netscape::Cache::Object($key, $value) : undef;
}

=head2 delete_object

Deletes URL from cache index and the related file from the cache.

B<WARNING:> Don't use B<delete_object> while in a B<next_object> loop!
It is better to collect all objects for delete in a list and do the
deletion after the loop, otherwise you can get strange behaviour (e.g.
malloc panics).

=cut

sub delete_object {
    my($self, $url) = @_;
    my $f = $self->{'CACHEDIR'} . "/" . $url->{'CACHEFILE'};
    if (-e $f) {
	return undef if !unlink $f;
    }
    delete $self->{'CACHE'}->{$url->{'_KEY'}};
}

=head2 rewind

    $cache->rewind();

This method is used to move the cache index's internal pointer
to the first URL in the cache index.
You don't need to bother with this if you have just created the object,
but it doesn't harm anything if you do.

=cut

sub rewind {
    my $self = shift;
    reset %{ $self->{'CACHE'} };
}

sub DESTROY {
    my $self = shift;
    untie %{ $self->{'CACHE'} };
}

# internal subroutine to get the cache directory from Netscape's preferences
sub get_cache_dir {
    my $cache_dir;
    if (open(PREFS, "$ENV{'HOME'}/.netscape/preferences")) {
	while(<PREFS>) {
	    if (/^CACHE_DIR:\s*(.*)$/) {
		$cache_dir = $1;
		last;
	    }
	}
	close PREFS;
    }
    $cache_dir;
}

package Netscape::Cache::Object;
use strict;
use vars qw($DEBUG);

$DEBUG = $Netscape::Cache::DEBUG;

=head1 Netscape::Cache::Object

C<next_object> and C<get_object> return an object of the class
C<Netscape::Cache::Object>. This object is simply a hash, which members
have to be accessed directly (no methods).

An example:

    $o = $cache->next_object;
    print $o->{'URL'}, "\n";

=over 4

=item URL

The URL of the cached object

=item CACHEFILE

The filename of the cached URL in the cache directory. To construct the full
path use ($cache is a Netscape::Cache object and $o a Netscape::Cache::Object
object)

    $cache->{'CACHEDIR'} . "/" . $o->{'CACHEFILE'}

=item CACHEFILE_SIZE

The size of the cache file.

=item CONTENT_LENGTH

The length of the cache file as specified in the HTTP response header.
In general, SIZE and CONTENT_LENGTH are equal. If you interrupt a transfer of
a file, only the first part of the file is written to the cache, resulting
in a smaller CONTENT_LENGTH than SIZE.

=item LAST_MODIFIED

The date of last modification of the URL as unix time (seconds since
epoch). Use

    scalar localtime $o->{'LAST_MODIFIED'}

to get a human readable date.

=item LAST_VISITED

The date of last visit.

=item EXPIRE_DATE

If defined, the date of expiry for the URL.

=item MIME_TYPE

The MIME type of the URL (eg. text/html or image/jpeg).

=item ENCODING

The encoding of the URL (eg. x-gzip for gzipped data).

=item CHARSET

The charset of the URL (eg. iso-8859-1).

=back

=cut

sub new {
    my($pkg, $key, $value) = @_;

    return undef if $value eq '';

    my $url = url($key);
    return undef if !$url;

    my $self = {};
    bless $self, $pkg;
    $self->{'URL'} = $url;

    $self->{'_KEY'} = $key;

    my($rest, $len, $last_modified, $expire_date);
    ($self->{'_XXX_FLAG_1'},
     $last_modified, 
     $self->{'LAST_VISITED'},
     $expire_date,
     $self->{'CACHEFILE_SIZE'},
     $self->{'_XXX_FLAG_2'}) = unpack("l6", substr($value, 4));
    ($self->{'CACHEFILE'}, $rest) = split(/\000/, substr($value, 33), 2);
    $self->{'_XXX_FLAG_3'} = unpack("l", substr($rest, 4, 4));
    $self->{'_XXX_FLAG_4'} = unpack("l", substr($rest, 25, 4));
    $self->{'LAST_MODIFIED'} = $last_modified if $last_modified != 0;
    $self->{'EXPIRE_DATE'} = $expire_date if $expire_date != 0;
    
    if ($DEBUG) {
	$self->_report(1, $key, $value, 
		       "<".substr($rest, 0, 4)."><".substr($rest, 8, 17)
		       ."><".substr($rest, 29, 4).">")
	  if substr($rest, 0, 4) =~ /[^\000]/ ||
	    substr($rest, 8, 17) =~ /[^\000]/ ||
	      substr($rest, 29, 4) =~ /[^\000]/;
    }
    
    $len = unpack("l", substr($rest, 33, 4));
    if ($len) {
	$self->{'MIME_TYPE'} = substr($rest, 37, $len-1);
    }
    $rest = substr($rest, 37 + $len);
    
    $len = unpack("l", substr($rest, 0, 4));
    if ($len) {
	$self->{'ENCODING'} = substr($rest, 4, $len-1);
    }
    $rest = substr($rest, 4 + $len);
    
    $len = unpack("l", substr($rest, 0, 4));
    if ($len) {
	$self->{'CHARSET'} = substr($rest, 4, $len-1);
    }
    $rest = substr($rest, 4 + $len);
    
    $self->{'CONTENT_LENGTH'} = unpack("l", substr($rest, 1, 4));
    
    if ($DEBUG) {
	$self->_report(2, $key, $value)
	  if substr($rest, 5) =~ /[^\000]/;
	
	my $record_length = unpack("l", substr($value, 0, 4));
	warn "Invalid length for value of <$key>\n"
	  if $record_length != length($value);
	$self->_report(3, $key, $value)
	  if $self->{'_XXX_FLAG_1'} != 3;
	$self->_report(4, $key, $value)
	  if $self->{'_XXX_FLAG_2'} != 0 && $self->{'_XXX_FLAG_2'} != 1;
	$self->_report(5, $key, $value)
	  if $self->{'_XXX_FLAG_3'} != 1;
	$self->_report(6, $key, $value)
	  if $self->{'_XXX_FLAG_4'} != 0 && $self->{'_XXX_FLAG_4'} != 1;
    }

    $self;
}

sub url {
    my $key = shift;
    my $keylen2 = unpack("l", substr($key, 4, 4));
    my $keylen1 = unpack("l", substr($key, 0, 4));
    if ($keylen1 == $keylen2 + 12) {
	substr($key, 8, $keylen2-1);
    } # else probably one of INT_CACHESIZE etc. 
}

sub _report {
    my($self, $errno, $key, $value, $addinfo) = @_;
    if ($self->{'_ERROR'} && $DEBUG < 2) {
	warn "Error number $errno\n";
    } else {
	warn
	  "Please report:\nError number $errno\nURL: "
	    . $self->{'URL'} . "\nEncoded URL: <"
	      . join("", map { sprintf "%2x", ord $_ } split(//, $key))
		. ">\nEncoded Properties: <"
		  . join("", map { sprintf "%2x", ord $_ } split(//, $value))
		    . ">\n"
		      . ($addinfo ? "Additional Info: <$addinfo>\n" : "")
			. "\n";
    }	
    $self->{'_ERROR'}++;
}

sub _make_key_from_url {
    my $url = shift;
    pack("l", length($url)+13) . pack("l", length($url)+1)
      . $url . ("\000" x 5);
}

=head1 AN EXAMPLE PROGRAM

This program loops through all cache objects and prints a HTML-ified list.
The list ist sorted by URL, but you can sort it by last visit date or size,
too.

    use Netscape::Cache;

    $cache = new Netscape::Cache;

    while ($o = $cache->next_object) {
        push(@url, $o);
    }
    # sort by name
    @url = sort {$a->{'URL'} cmp $b->{'URL'}} @url;
    # sort by visit time
    #@url = sort {$b->{'LAST_VISITED'} <=> $a->{'LAST_VISITED'}} @url;
    # sort by mime type
    #@url = sort {$a->{'MIME_TYPE'} cmp $b->{'MIME_TYPE'}} @url;
    # sort by size
    #@url = sort {$b->{'CACHEFILE_SIZE'} <=> $a->{'CACHEFILE_SIZE'}} @url;

    print "<ul>\n";
    foreach (@url) {
        print
          "<li><a href=\"file:",
          $cache->{'CACHEDIR'},
	  "/", $_->{'CACHEFILE'}, "\">",
          $_->{'URL'}, "</a> ",
	  scalar localtime $_->{'LAST_VISITED'}, "<br>",
          "type: ", $_->{'MIME_TYPE'}, 
	  ",size: ", $_->{'CACHEFILE_SIZE'}, "\n";
    }
    print "</ul>\n";

=head1 ENVIRONMENT

The Netscape::Cache module examines the following environment variables:

=over 4

=item HOME

Home directory of the user, used to find Netscape's preferences
($HOME/.netscape).

=back

=head1 BUGS

There are still some unknown fields (_XXX_FLAG_{1,2,3}).

You can't use B<delete_object> while looping with B<next_object>.

=head1 SEE ALSO

L<Netscape::History>

=head1 AUTHOR

Slaven Rezic <eserte@cs.tu-berlin.de>

=head1 COPYRIGHT

Copyright (c) 1997 Slaven Rezic. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
