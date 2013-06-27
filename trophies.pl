#!/usr/bin/perl
use strict;
use warnings;

my $id = 0;
my $asc = 0;

my @trophies =
(
  'None', 
  'The Gold Star',      # make it to Earth
  'The Platinum Star',  # make it to Astral
  'The Dilithium Star', # ascend
  'The Birdie',         # ascend both genders
  'The Double Top',     # previous + ascend all three aligns
  'The Hat Trick',      # previous + ascend all five races
  'The Grand Slam',     # previous + ascend all thirteen roles
  'The Full Monty'      # previous + ascend all twelve conducts
);

my @achievements;

# Each of the following hashes contains the information of the game that is currently winning the trophy.
my (%asc_first, %asc_turns, %asc_low, %asc_high, %asc_conduct, %asc_lowhp, %asc_rich, %asc_lifesaved, %asc_efficient);
my (%nasc_high);

# Multi-game trophy
my %plr_asc;   # $plr_asc{player} = number of times player has ascended
my %plr_games; # $plr_games{player}= number of games player has played
my %plr_last;  # %{$plr_last{player}} contains the information of their last
               # ascension
my %games;     # @{$games{player}} contains the information of their ascensions
               # and each death is recorded but not with the full game

# For keeping track of best of 13 (calculated after main loop)
my $b13 = 0;      # best "best of 13" score seen thus far
my $b13_plr = ''; # current trophy holder

# For keeping track of max average dungeon depth.
my %plr_depth;    # %plr_depth{player} = number of dungeon levels reached
my $deepest = ''; # $deepest is the player who has been deepest on average

# For keeping track of ascension streaks
my %streak_best;      # Player's best streak
my %streak_best_last; # Last game of player's best streak
my %streak_cur;       # Player's current streak (if any)

# For keeping track of unique deaths (note: unique deaths are calculated at the very end as there's really no need to break ties)
my $uniq_best = 0;
my $uniq_plr = '';
my $uniq_cnt = `./tuniquedeaths.pl -c`;  # number of possible unique deaths

# %{$asc_role{Rol}} contains the information of the game that is currently the high-scoring Rol game
my %role_high;

my %expand =
(
  'Arc' => 'Archeologist',
  'Bar' => 'Barbarian',
  'Cav' => 'Cave(wo)man',
  'Hea' => 'Healer',
  'Kni' => 'Knight',
  'Mon' => 'Monk',
  'Pri' => 'Priest(ess)',
  'Rog' => 'Rogue',
  'Ran' => 'Ranger',
  'Sam' => 'Samurai',
  'Tou' => 'Tourist',
  'Val' => 'Valkyrie',
  'Wiz' => 'Wizard',

  'Dwa' => 'Dwarf',
  'Elf' => 'Elf',
  'Gno' => 'Gnome',
  'Hum' => 'Human',
  'Orc' => 'Orc',

  'Fem' => 'Female',
  'Mal' => 'Male',

  'Law' => 'Lawful',
  'Neu' => 'Neutral',
  'Cha' => 'Chaotic',
);

# Returns the best_of_13 score for player.
# Note that if a player plays only only two games, both games are ascensions
#   and of the same role-race-gender-align, it's scored as 1, not 0.
sub best_of_13
{
  my $player = shift;
  my $best = 0;
  my $lastid = 0;
  my ($i, $j, $cur, $id);
  my %seen;
 
  for ($i = 0; $i < $plr_games{$player}; ++$i)
  {
    %seen = ();
    $cur = 0;

    for ($j = $i; $j < 13 + $i && $j < $plr_games{$player}; ++$j)
    {
      next unless $games{$player}[$j]{ascended};
      last if $seen{$games{$player}[$j]{crga}}++;
      ++$cur;   
      $id = $games{$player}[$j]{id};
    }

    ($best, $lastid) = ($cur, $id) if $cur > $best;
  }
  
  return $best;
}

sub earned_bell
{
  my $player  = shift;
  my $bell    = shift;
  my $succeed = 0;
  my %roles;
  my %races;
  my %genders;
  my %aligns;
  my %conducts;

  foreach (@{$games{$player}})
  {
    my %game = %{$_};

    goto clear unless $game{ascended};
    goto clear if $genders{$game{gender}}++ && $bell == 4;
    goto clear if $aligns{$game{align}}++   && $bell == 5;
    goto clear if $races{$game{race}}++     && $bell == 6;
    goto clear if $roles{$game{role}}++     && $bell == 7;

    my $newconduct = 0;
    foreach my $conduct (split / /, $game{conduct})
    {
      ++$newconduct unless $conducts{$conduct}++;
    }
    goto clear if !$newconduct && $bell == 8;

    # Our game counts toward the current bell, let's see if we succeeded in getting it.
    {{
       last if keys(%genders)  < 2  && $bell >= 4;
       last if keys(%aligns)   < 3  && $bell >= 5;
       last if keys(%races)    < 5  && $bell >= 6;
       last if keys(%roles)    < 13 && $bell >= 7;
       last if keys(%conducts) < 12 && $bell >= 8;
       return 1;
    }}
  
    # We didn't succeed in getting the bell, but we're also okay as far as duplicated effort is concerned.
    next;

    clear: # Our game didn't count for the current bell.
    %roles = %races = %genders = %aligns = %conducts = ();
    
    # but it may count for the next attempt!
    next unless $game{ascended};
    ++$roles{$game{role}};
    ++$races{$game{race}};
    ++$genders{$game{gender}};
    ++$aligns{$game{align}};
    ++$conducts{$_} foreach (split / /, $game{conduct});
  }

  return 0;
}

sub achievement
{
  my $player = shift;
  my ($best, $bestbell) = (0, 0);

  my %roles;
  my %races;
  my %genders;
  my %aligns;
  my %conducts;

  foreach (@{$games{$player}})
  {
    my %game = %{$_};
    $best = 1 if $game{curdlvl} < 0  && $game{curdlvl} > -6 && $best < 1;
    $best = 2 if $game{curdlvl} == -5                       && $best < 2;
    next unless $game{ascended};
    $best = 3;

    ++$roles{$game{role}};
    ++$races{$game{race}};
    ++$genders{$game{gender}};
    ++$aligns{$game{align}};
    ++$conducts{$_} foreach (split / /, $game{conduct});
  }

  if ($best == 3)
  {{
                last if keys(%genders)  < 2;
     $best = 4, last if keys(%aligns)   < 3;
     $best = 5, last if keys(%races)    < 5;
     $best = 6, last if keys(%roles)    < 13;
     $best = 7, last if keys(%conducts) < 12;
     $best = 8;
  }}

  for (4..$best)
  {
    $bestbell = $_ if earned_bell($player, $_);
  }

  return ($best, $bestbell);
}

while (<>)
{
  my ($score, $curdlvl, $maxdlvl, $curhp, $maxhp, $lifesaved,
      $turns, $gold, $kills, $startdate, $enddate, $crga, $role,
      $race, $gender, $align, $conduct, $player, $death) =
/^(\d+) (-?\d+) (\d+) (-?\d+) (-?\d+) (\d+) (\d+) (\d+) (\d+) (\d{8}) (\d{8}) (([A-Z][a-z][a-z]) ([A-Z][a-z][a-z]) ([MF][a-z][a-z]) ([LNC][a-z][a-z])) \{([^}]*)\} (.+?),(.+)$/;

  if (!defined($death))
  {
    print STDERR "Unable to parse logline $.. Skipping.\n";
    next;
  }
  
  #next unless $startdate =~ /^200606/ && $enddate =~ /^200606/;

  my $ascended = ($death eq 'ascended' ? 1 : 0);
  my @conducts = split / /, $conduct;
  my $conduct_cnt = @conducts;
  my $depth = $maxdlvl;
     $depth -= $curdlvl if $curdlvl < 0 && $curdlvl > -6;

  ++$id;

  my %game =
  (
    id          => $id,
    ascended    => $ascended,
    score       => $score,
    curdlvl     => $curdlvl,
    maxdlvl     => $maxdlvl,
    curhp       => $curhp,
    maxhp       => $maxhp,
    lifesaved   => $lifesaved,
    turns       => $turns,
    gold        => $gold,
    kills       => $kills,
    startdate   => $startdate,
    enddate     => $enddate,
    crga        => $crga,
    role        => $role,
    race        => $race,
    gender      => $gender,
    align       => $align,
    conduct_cnt => $conduct_cnt,
    conduct     => $conduct,
    player      => $player,
    death       => $death,
  );
  
  ++$plr_games{$player};
  $plr_depth{$player} += $depth;

  if ($ascended)
  {
    ++$asc;
    ++$plr_asc{$player};
    $plr_last{$player} = \%game;

    ++$streak_cur{$player};
    if (!defined($streak_best{$player}) || $streak_cur{$player} > $streak_best{$player})
    {
      $streak_best{$player} = $streak_cur{$player};
      $streak_best_last{$player} = \%game;
    }

    if (!%asc_first)
    {
      %asc_first     =
      %asc_turns     =
      %asc_low       = 
      %asc_high      =
      %asc_conduct   = 
      %asc_lowhp     =
      %asc_rich      = 
      %asc_lifesaved =
      %asc_efficient =
                       %game;
    }
    else
    {
      %asc_turns     = %game if $turns       < $asc_turns{turns};
      %asc_low       = %game if $score       < $asc_low{score};
      %asc_high      = %game if $score       > $asc_high{score};
      %asc_conduct   = %game if $conduct_cnt > $asc_conduct{conduct_cnt};
      %asc_lowhp     = %game if $maxhp       < $asc_lowhp{maxhp};
      %asc_rich      = %game if $gold        > $asc_rich{gold};
      %asc_lifesaved = %game if $lifesaved   > $asc_lifesaved{lifesaved};

      %asc_efficient = %game if
                                $score/$turns 
                              > $asc_efficient{score}/$asc_efficient{turns};
    }
  }
  else # not an ascension
  {
    $streak_cur{$player} = 0;

    %nasc_high = %game if !%nasc_high || $score > $nasc_high{score};
  }

  $role_high{$role} = \%game if 
                                !defined($role_high{$role}{score})
                             || $score > $role_high{$role}{score};

  if ($ascended)
  {
    push @{$games{$player}}, \%game;
  }
  else
  {
    push @{$games{$player}}, {curdlvl => $curdlvl, ascended => 0};
  }
}

# Calculate best_of_13 score for each player.
foreach my $player (keys %plr_asc)
{
  my $count = best_of_13($player);
  ($b13, $b13_plr) = ($count, $player) if $count > $b13;
}

# Calculate unique deaths for each player.
foreach my $player (keys %plr_games)
{
  my $count = `./tuniquedeaths.pl ../public_html/nh/tourney/$player.logfile.txt`;
  ($uniq_best, $uniq_plr) = ($count, $player) if $count > $uniq_best;
}

# Calculate average dungeon depth for each player.
$deepest = $asc_first{player}; # Gotta start somewhere!
foreach my $player (keys %plr_games)
{
  $deepest = $player if 
                        $plr_depth{$player}  / $plr_games{$player}
                      > $plr_depth{$deepest} / $plr_games{$deepest};
}

# Calculate achievement trophies for everyone.
foreach my $player (keys %plr_games)
{
  my ($best, $bell) = achievement($player);
  if ($best == $bell)
  {
    unshift @{$achievements[$best]}, $player . ' (with bells on)';
  }
  else
  {
    push @{$achievements[$best]}, $player;
    unshift @{$achievements[$bell]}, $player . ' (with bells on)' if $bell >= 4;
  }
}

open(PLAINTEXT, '>trophies.txt');
print PLAINTEXT "The June 2006 nethack.alt.org Tournament Trophy Winners\n\n";

# Print out trophy winners!
my $time = gmtime;
print << "EOHD";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>The June 2006 nethack.alt.org Tournament Trophy Winners</title>
    <link rel="stylesheet" type="text/css" href="trophy.css" />
  </head>

  <body>
    <h2>The June 2006 <a href="http://alt.org/nethack/">nethack.alt.org</a> Tournament Trophy Winners</h2>
    <p><small>
      Last calculated: $time UTC<br />
      <a href="trophies.txt">Plaintext version</a><br />
      <a href="index.html">Tournament information</a>
    </small></p>
    <hr />
EOHD

print '<div class="major multi"><span class="title">Multiple Ascension Trophies</span><ul>';
print PLAINTEXT "Multiple Ascension Trophies:\n";

printf '<li>Best of 13: <span class="player">%s</span> with %d ascensions.</li>', $b13_plr, $b13;
printf PLAINTEXT "  Best of 13:               %s with %d ascensions.\n", $b13_plr, $b13;

# Sort by ascension count descending, then by game ID ascending.
foreach (sort {$plr_asc{$b} <=> $plr_asc{$a} || $plr_last{$a}{id} <=> $plr_last{$b}{id}} keys %plr_asc)
{
  printf '<li>Most Ascensions: <span class="player">%s</span> with %d total ascensions.</li>', $_, $plr_asc{$_};
  printf PLAINTEXT "  Most Ascensions:          %s with %d total ascensions.\n", $_, $plr_asc{$_};
  last;
}

# Sort by ascension streak length descending, then by game ID ascending.
foreach (sort {$streak_best{$b} <=> $streak_best{$a} || $streak_best_last{$a}{id} <=> $streak_best_last{$b}{id}} keys %streak_best)
{
  printf '<li>Longest Ascension Streak: <span class="player">%s</span> with %d consecutive ascensions.</li>', $_, $streak_best{$_};
  printf PLAINTEXT "  Longest Ascension Streak: %s with %d consecutive ascensions.\n", $_, $streak_best{$_};
  last;
}

print '</ul></div><div class="major single"><span class="title">Single Ascension Trophies</span><ul>';
print PLAINTEXT "\nSingle Ascension Trophies:\n";

printf '<li>First Ascension: <span class="player">%s</span>, tournament game #%d.</li>', $asc_first{player}, $asc_first{id};
printf PLAINTEXT "  First Ascension:           %s, tournament game #%d.\n", $asc_first{player}, $asc_first{id};

printf '<li>Highest-Scoring Ascension: <span class="player">%s</span> with %d points.</li>', $asc_high{player}, $asc_high{score};
printf PLAINTEXT "  Highest-Scoring Ascension: %s with %d points.\n", $asc_high{player}, $asc_high{score};

printf '<li>Lowest-Scoring Ascension: <span class="player">%s</span> with %d points.</li>', $asc_low{player}, $asc_low{score};
printf PLAINTEXT "  Lowest-Scoring Ascension:  %s with %d points.\n", $asc_low{player}, $asc_low{score};

printf '<li>Fastest Ascension (turns): <span class="player">%s</span> in %d turns.</li>', $asc_turns{player}, $asc_turns{turns};
printf PLAINTEXT "  Fastest Ascension (turns): %s in %d turns.\n", $asc_turns{player}, $asc_turns{turns};

printf '<li>Best-Behaved Ascension: <span class="player">%s</span> adhered to %d conducts: %s.</li>', $asc_conduct{player}, $asc_conduct{conduct_cnt}, $asc_conduct{conduct};
printf PLAINTEXT "  Best-Behaved Ascension:    %s adhered to %d conducts: %s.\n", $asc_conduct{player}, $asc_conduct{conduct_cnt}, $asc_conduct{conduct};

printf '<li>Lowest HP Ascension: <span class="player">%s</span> with %d maximum HP.</li>', $asc_lowhp{player}, $asc_lowhp{maxhp};
printf PLAINTEXT "  Lowest HP Ascension:       %s with %d maximum HP.\n", $asc_lowhp{player}, $asc_lowhp{maxhp};

printf '<li>Richest Ascension: <span class="player">%s</span> carried %d zorkmids to the high altar.</li>', $asc_rich{player}, $asc_rich{gold};
printf PLAINTEXT "  Richest Ascension:         %s carried %d zorkmids to the high altar.\n", $asc_rich{player}, $asc_rich{gold};

printf '<li>Most Lifesaved Ascension: <span class="player">%s</span> activated %d amulets of life saving.</li>', $asc_lifesaved{player}, $asc_lifesaved{lifesaved};
printf PLAINTEXT "  Most Lifesaved Ascension:  %s activated %d amulets of life saving.\n", $asc_lifesaved{player}, $asc_lifesaved{lifesaved};

printf '<li>Most Efficient Ascension: <span class="player">%s</span> with %d/%d (%.2f) points/turn.</li>', $asc_efficient{player}, $asc_efficient{score}, $asc_efficient{turns}, $asc_efficient{score}/$asc_efficient{turns};
printf PLAINTEXT "  Most Efficient Ascension:  %s with %d/%d (%.2f) points/turn.\n", $asc_efficient{player}, $asc_efficient{score}, $asc_efficient{turns}, $asc_efficient{score}/$asc_efficient{turns};

print '</ul></div><div class="major misc"><span class="title">Miscellaneous Trophies</span><ul>';
print PLAINTEXT "\nMiscellaneous Trophies:\n";

printf '<li>Highest-Scoring Nonascension: <span class="player">%s</span> with %d points.</li>', $nasc_high{player}, $nasc_high{score};
printf PLAINTEXT "  Highest-Scoring Nonascension: %s with %d points.\n", $nasc_high{player}, $nasc_high{score};

printf '<li>Most Unique Deaths: <a href="%s.deaths.txt"><span class="player">%s</span></a> with %d/%d (%.2f) possible deaths.</li>', $uniq_plr, $uniq_plr, $uniq_best, $uniq_cnt, 100*$uniq_best/$uniq_cnt;
printf PLAINTEXT "  Most Unique Deaths:           %s with %d/%d (%.2f) possible deaths.\n", $uniq_plr, $uniq_best, $uniq_cnt, 100*$uniq_best/$uniq_cnt;

printf '<li>Lowest Average Dungeon Level: <span class="player">%s</span> with an average depth of %.2f.</li>', $deepest, $plr_depth{$deepest} / $plr_games{$deepest};
printf PLAINTEXT "  Lowest Average Dungeon Level: %s with an average depth of %.2f.\n", $deepest, $plr_depth{$deepest} / $plr_games{$deepest};

print '</ul></div><div class="major role"><span class="title">Role High Score Trophies</span><ul>';
print PLAINTEXT "\nRole High Score Trophies:\n";

foreach (sort keys %role_high)
{
  my %game = %{$role_high{$_}};
  printf '<li>%s: <span class="player">%s</span> with %d points.</li>', $expand{$_}, $game{player}, $game{score};
  printf PLAINTEXT "  %s:%s%s with %d points.\n", $expand{$_}, ' ' x (13 - length($expand{$_})), $game{player}, $game{score};
}

print '</ul></div><div class="major achievement"><span class="title">Achievement Trophies</span><ul>';
print PLAINTEXT "\nAchievement Trophies:\n";
foreach (8, 7, 6, 5, 4, 3, 2, 1)
{
  next unless $achievements[$_];
  print '<li>';
  print $trophies[$_];
  print '<ul>';
  print PLAINTEXT "  " . $trophies[$_] . "\n";
  foreach (sort {!!($b =~ /bells on/) <=> !!($a =~ /bells on/) || lc($a) cmp lc($b)} @{$achievements[$_]})
  {
    my $bells = /bells on/;
    printf '<li>%s<span class="player">%s</span>%s</li>', $bells ? '<span class="bell">' : '', $_, $bells ? '</span>' : '';
    print PLAINTEXT "    $_\n";
  }
  print '</ul>';
  print '</li>';
}

print << "EOHD";
      </ul>
    </div>
  </body>
</html>
EOHD

