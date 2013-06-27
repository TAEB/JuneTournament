#!/usr/bin/perl
use strict;
use warnings;

my $logfile      = '/opt/nethack/nethack.dtype.org/var/logfile';
my $nhdumpdir    = '/opt/nethack/nethack.dtype.org/dgldir/dumplog/';
my $localdumpdir = './chardump/';
my $lastwc       = './wc.txt';

my $prev_wc = int `cat $lastwc`;
my $cur_wc  = `wc -l $logfile`;
($cur_wc) = $cur_wc =~ /(\d+)/;
system("echo $cur_wc > $lastwc");

my $new_games = $cur_wc - $prev_wc;
my $id = $prev_wc;

foreach (split /\n/, `tail -n$new_games $logfile`)
{
  ++$id;
  my $time = time;

  # my ($player) = /^3.\d.\d+ [\d\-]+ [\d\-]+ [\d\-]+ [\d\-]+ [\d\-]+ [\d\-]+ \d+ \d+ \d+ \d+ [A-Z][a-z]+ [A-Z][a-z]+ [MF][a-z]+ [A-Z][a-z]+ ([^,]+),.*$/;
  my ($player) = / ([^ ,]+),/;

  # -p makes it so if the directory is existant it will silently fail
  system("mkdir -p $localdumpdir$player/");

  # Don't copy if the two files are the same
  next unless system("diff $nhdumpdir$player.lastgame.txt $localdumpdir$player/$player.lastgame.txt > /dev/null");

  # Copy to both places to make it easier to diff and for better Rodney 
  # integration ("!lastgame player" will always give the most recent game, 
  # person should link to player.<time>.txt for posterity)
  system("cp $nhdumpdir$player.lastgame.txt $localdumpdir$player/$player.$time.txt");
  system("cp $nhdumpdir$player.lastgame.txt $localdumpdir$player/$player.lastgame.txt");
}

