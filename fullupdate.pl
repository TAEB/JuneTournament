#!/usr/bin/perl -l
use strict;
use warnings;

if ((stat "trophies.pl")[9] > (stat ".trophy_time")[9])
{
  system("time perl trophies.pl");
}
else
{
  print "Skipping recalculation of trophies.";
}

print "Creating FAQ";
system("perl make_faq.pl faq.txt > faq.html");

print "Compressing all pages";
system("tar -jcf pages.tbz2 index.html faq.html player.css scoreboard.html scoreboard.txt players.html players.txt player clan trophy");

print "Uploading tarball";
system("scp pages.tbz2 katron.org:public_html/nh/07/");
system("rm pages.tbz2");

print "Extracting tarball remotely";
system("ssh katron.org 'cd public_html/nh/07 && tar -jxf pages.tbz2 && rm pages.tbz2'");

