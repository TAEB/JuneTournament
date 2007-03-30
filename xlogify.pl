#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;

die "$0: I refuse to run, there's a .lock file." if -e ".lock";
system('touch .lock');

sub my_die # {{{
{
  my $text = join ' ', @_;
  open my $handle, '>', '.lock'
    or die "Unable to open .lock file for writing: $!",
           "propagated by $text";
  printf {$handle} "time: %s\nreason: ", scalar localtime, $text;
  die $text;
} # }}}

sub demunge_conduct # {{{
{
  my $conduct = hex(shift);
  my @achieved;

  foreach
  (
    [foodless     => 0x0001],
    [vegan        => 0x0002],
    [vegetarian   => 0x0004],
    [atheist      => 0x0008],
    [weaponless   => 0x0010],
    [pacifist     => 0x0020],
    [illiterate   => 0x0040],
    [polyitemless => 0x0080],
    [polyselfless => 0x0100],
    [wishless     => 0x0200],
    [artiwishless => 0x0400],
    [genoless     => 0x0800],
  )
  {
    push @achieved, $_->[0] if $conduct & $_->[1];
  }

  return @achieved;
} # }}}

sub demunge_logline # {{{
{
  local $_ = shift;
  return {} unless my @captures = m{
         ^                    # start of line
         (3.\d.\d+)        \  # version
         ([\d\-]+)         \  # score
         ([\d\-]+)         \  # death dungeon number
         ([\d\-]+)         \  # death dungeon level
         ([\d\-]+)         \  # deepest dungeon level
         ([\d\-]+)         \  # hp at death
         ([\d\-]+)         \  # maximum hp
         (\d+)             \  # number of deaths
         (\d+)             \  # end date
         (\d+)             \  # start date
         (\d+)             \  # uid
         ([A-Z][a-z][a-z]) \  # role
         ([A-Z][a-z][a-z]) \  # race
         ([MF][a-z][a-z])  \  # gender
         ([A-Z][a-z][a-z]) \  # align
         ([^,]+)              # player name
         ,                    # literal comma
         (.*)                 # death reason
         $                    # end of line
         }x;

  my %game;

  @game{'version', 'points', 'deathdnum', 'deathlev', 'maxlvl', 'hp', 'maxhp', 
        'deaths', 'deathdate', 'birthdate', 'uid', 'role', 'race', 'gender', 
        'align', 'name', 'death'} = @captures;

  $game{ascended}   = $game{death} eq 'ascended' ? 1 : 0;
  $game{conducts}   = scalar demunge_conduct($game{conduct});
  $game{endtime}    = $game{num} unless exists $game{endtime};
  $game{gender0}  ||= $game{gender};
  $game{align0}   ||= $game{align};
  $game{crga0}      = join ' ', @game{qw/role race gender0 align0/};

  return \%game;
} # }}}

sub demunge_xlogline # {{{
{
  my %game;
  foreach (split /:/, shift)
  {
    next unless /^([^=]+)=(.*)$/;
    $game{$1} = $2;
  }
  return \%game;
} # }}}

sub xlogify # {{{
{
  my $game_ref = shift;
  my $out = '';

  while (my ($k, $v) = each(%$game_ref))
  {
    for ($k, $v) { s/:/_/g }
    $out .= sprintf '%s=%s:', $k, $v;
  }

  chop $out;
  return $out;
} # }}}

sub dumplog_matches # {{{
{
  my ($dumplog, $game_ref) = @_;

  open my $out, '>', 'chardump.txt'
    or my_die "Unable to open chardump.txt for writing: $!";
  print {$out} $dumplog;
  close $out;

  my $xlogline = `./chardump.pl chardump.txt`;
  my $dump_ref = demunge_xlogline($xlogline);

  for
  (
    "name", "align", "race", "role",
  )
  {
    return 0 if  ref($_) && $game_ref->{$_->[0]} ne $dump_ref->{$_->[1]};
    return 0 if !ref($_) && $game_ref->{$_}      ne $dump_ref->{$_};
  }

  $game_ref->{unsure} = 0;
  return 1;
} # }}}

# Read all input {{{
my $num = do {local @ARGV = "num.txt"; <>};

open my $in, '<', 'intermediate_logfile'
  or my_die "Unable to open intermediate_logfile for reading: $!";
my @in = <$in>;
close $in;

open my $in_unsure, '<', 'xlogfile.unsure'
  or my_die "Unable to open xlogfile.unsure for reading: $!";
my @unsure = <$in_unsure>;
close $in_unsure;
# }}}

# Open output handles {{{
open my $out, '>>', 'xlogfile'
  or my_die "Unable to open xlogfile for appending: $!";
open my $out_unsure, '>', 'xlogfile.unsure'
  or my_die "Unable to open xlogfile.unsure for writing: $!";
# }}}

GAME: foreach (@in, @unsure)
{
  my $game_ref = demunge_logline($_);

  next unless $game_ref->{birthdate} =~ /^200704/ &&
              $game_ref->{deathdate} =~ /^200704/;

  if (!$game_ref->{unsure})
  {
    $game_ref->{num} = ++$num;
    $game_ref->{endtime} = $game_ref->{num};
  }

  if (!$game_ref->{ascended})
  {
    print {$out} xlogify($game_ref);
    next GAME;
  }

  # 99% of the time, the lastgame.txt will be the correct dumplog, so optimize for that case
  my $last_dump = get("http://alt.org/nethack/dumplog/$game_ref->{name}.lastgame.txt");
  if (dumplog_matches($last_dump, $game_ref))
  {
    print {$out} xlogify($game_ref);
    next GAME;
  }

  my $index = get("http://alt.org/nethack/chardump/$game_ref->{name}");
  for (split /\n/, $index)
  {
    next unless m{/icons/text\.gif};
    next unless m{<a href="(\w+.(\d{8})-\d+.txt)">};

    # note that this won't work very well across month boundaries, but that's ok
    next unless abs($2 - $game_ref->{deathdate}) <= 1;

    my $dumplog = get("http://alt.org/nethack/chardump/$game_ref->{name}/$1");
    if (dumplog_matches($dumplog, $game_ref))
    {
      print {$out} xlogify($game_ref);
      next GAME;
    }
  }

  $game_ref->{unsure} = 1;
  print {$out_unsure} xlogify($game_ref);
}

open my $out_num, '>', 'num.txt'
  or my_die "Unable to open num.txt for writing: $!";
print {$out_num} $num;

unlink ".lock";

