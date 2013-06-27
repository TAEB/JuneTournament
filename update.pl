#!/usr/bin/perl
use Logfile;
use LWP::Simple;

# poor man's tail -f.. :)
my ($old) = (`wc -l logfile`) =~ /(\d+)/;
system('wget -c http://alt.org/nethack/logfile');
my ($new) = (`wc -l logfile`) =~ /(\d+)/;
my $diff = $new - $old;

my ($aold) = (`wc -l alogfile`) =~ /(\d+)/;
system('wget -c http://alt.org/nethack/tourney/alogfile');
my ($anew) = (`wc -l alogfile`) =~ /(\d+)/;
my $adiff = $anew - $aold;

open(TLOGFILE, ">>tlogfile");
foreach (split /\n/, `tail -n$diff logfile`)
{
  my %game = Logfile::parse_line($_);
  next unless $game{startdate} =~ /^200606/ && $game{enddate} =~ /^200606/;
  my ($turns, $gold, $kills, $conduct) = (0, 0, 0, '');
  my $char = $game{name};

  open(PLAYER, ">>../public_html/nh/tourney/$char.logfile.txt");
  print PLAYER $_;
  close PLAYER;

  system("./uniquedeaths.pl ../public_html/nh/tourney/$char.logfile.txt > ../public_html/nh/tourney/$char.deaths.txt");

  goto APPEND unless $game{ascended};
  my $dump;

  foreach (split /\n/, `tail -n$adiff logfile`)
  {
    my ($id) = s/-(\d+)//;
    my %agame = Logfile::parse_line($_);
    next unless $agame{name} eq $game{name};
    next unless $agame{score} == $game{score};
    next unless $agame{crga} eq $game{crga};
    $dump = get("http://alt.org/nethack/tourney/tourney/$char.$id.txt");
    last;
  }

  goto APPEND if (!defined $dump || $dump eq '');

  open(LASTGAME, ">../public_html/nh/tourney/$char.lastgame.txt");
  print LASTGAME $dump;
  close LASTGAME;
  
  system("mkdir -p $char/");
  system("cp ../public_html/nh/tourney/$char.lastgame.txt $char/lastgame.txt");
  system("./chardump.pl $char/lastgame.txt > $char/report.txt");
  my $report = `cat $char/report.txt`;
  
  my $id = 0;
  my $ls = `ls -1 $char/`;
  while ($ls =~ s/^(\d+)\.lastgame\.txt$//m)
  {
    $id = $1 if $id < $1;
  }
  $id++;
  $id = '0' x (5 - length $id) . $id;

  system("mv $char/lastgame.txt $char/$id.lastgame.txt");
  system("mv $char/report.txt $char/$id.report.txt");

  ($turns)    = $report =~ /^Turns: (\d+)$/m;
  ($gold)     = $report =~ /^Gold: (\d+)$/m;
  ($kills)    = $report =~ /^Vanquished: (\d+)$/m;
  ($conduct)  = $report =~ /^Conducts \(\d+\): (.*)$/m;

APPEND:

  print TLOGFILE "$game{score} $game{curdlvl} $game{maxdlvl} $game{curhp} $game{maxhp} $game{lifesaved} $turns $gold $kills $game{startdate} $game{enddate} $game{role} $game{race} $game{gender} $game{align} {$conduct_str} $game{name},$game{death}\n";
}

