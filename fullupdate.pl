#!/usr/bin/perl -l
use strict;
use warnings;

die "$0: I refuse to run, there's a .lock file." if -e ".lock";

my $trophies = (stat "trophies.pl") [9];
my $logfile  = (stat "xlogfile")    [9];
my $last     = (stat ".trophy_time")[9];

if ($logfile > $last || $trophies > $last)
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
system("ssh katron.org 'cd public_html/nh/07 && rm player/* clan/* trophy/* && tar -jxf pages.tbz2 && rm pages.tbz2'");

