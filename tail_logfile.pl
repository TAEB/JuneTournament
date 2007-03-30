#!/usr/bin/perl
use strict;
use warnings;

die "$0: I refuse to run, there's a .lock file." if -e ".lock";

my $input = 'http://alt.org/nethack/logfile';
my $output = 'intermediate_logfile';

exec("tail -n0 -s0.3 -f logfile > $output") unless fork;

system("wget -qc $input");
sleep 1; # make sure tail sees the new output before we kill it
kill -9 => $$;

