#!/usr/bin/perl
use strict;
use warnings;

die "$0: I refuse to run, there's a .lock file." if -e ".lock";
system('touch .lock');

system('touch .trophy_time');

my $devnull = 0;

# Global variables {{{
my @games;
my @ascensions;
my %games_for;
my %ascensions_for;
my %unsure_for;
my %achievements;
my %achievement_for;
my %clan_games;
my %clan_ascs;
my %best_ascstreak_for;
my %clan_of;
my %clan_roster;
my %clan_points_for;
my %txt_output_for;
my %html_output_for;
my %clan_txt_output_for;
my %clan_html_output_for;
my %html_status;
my %txt_status;
# }}}

# Constants {{{
my @points_for_position = (1.00, .60, .30);
my @roles = qw{Arc Bar Cav Hea Kni Mon Pri Ran Rog Sam Tou Val Wiz};
my @achievement_trophies =
qw(
  none
  gold
  platinum
  dilithium
  birdie
  doubletop
  hattrick
  grandslam
  fullmonty
);
my %achievement_trophies =
(
  gold      => 'The Gold Star',
  platinum  => 'The Platinum Star',
  dilithium => 'The Dilithium Star',
  birdie    => 'The Birdie',
  doubletop => 'The Double Top',
  hattrick  => 'The Hat Trick',
  grandslam => 'The Grand Slam',
  fullmonty => 'The Full Monty',
);
my %expand =
(
  Arc => 'Archeologist',
  Bar => 'Barbarian',
  Cav => 'Caveman',
  Hea => 'Healer',
  Kni => 'Knight',
  Mon => 'Monk',
  Pri => 'Priest',
  Ran => 'Ranger',
  Rog => 'Rogue',
  Sam => 'Samurai',
  Tou => 'Tourist',
  Val => 'Valkyrie',
  Wiz => 'Wizard',
);
# }}}

sub my_die # {{{
{
  my $text = join ' ', @_;
  open my $handle, '>', '.lock'
    or die "Unable to open .lock file for writing: $!",
           "propagated by $text";
  printf {$handle} "time: %s\nreason: %s\nstacktrace:\n", scalar localtime, $text;

  my $i = 1;
  while (1)
  {
    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask)
          = caller($i++) or last;

    printf {$handle} "  from %s, function %s (line %d)\n", $filename, $subroutine, $line;
  }

  die $text;
} # }}}

sub read_clan_info # {{{
{
  local @ARGV = @_;

  while (<>)
  {
    chomp;
    my ($nick, $clan) = split ':';
    next unless $nick && $clan;
    $clan_of{$nick} = $clan;
    $clan_roster{$clan}{$nick} = 1;
    $clan_txt_output_for{$clan} = $clan_html_output_for{$clan} = "";
  }
} # }}}

sub read_xlogfile # {{{
{
  my %seen;
  my %ascstreak_for;
  my $num = 0;

  local @ARGV = @_;

  while (<>)
  {
    my %game;

    if ($devnull)
    {
      s/^(\S+ )//;
      next if $seen{$1}++;
    }

    chomp;

    # parse the logfile.. ahh I love aardvarkj
    foreach (split /:/, $_)
    {
      next unless /^([^=]+)=(.*)$/;
      $game{$1} = $2;
    }

    next if $game{death} eq "a trickery";

    if ($devnull)
    {
      $game{ascended}   = $game{death} eq 'ascended' ? 1 : 0;
      $game{crga0}      = join ' ', @game{qw/role race gender0 align0/};
      $game{num}        = ++$num;
      $game{conducts}   = scalar demunge_conduct($game{conduct});
    }

    ++$unsure_for{$game{name}} if $game{unsure};
    push @{ $games_for{$game{name}} }, \%game;
    ++$clan_games{ $clan_of{$game{name}} } if exists $clan_of{$game{name}};

    if ($game{ascended})
    {
      ++$clan_ascs{ $clan_of{$game{name}} } if exists $clan_of{$game{name}};
      ++$ascensions_for{$game{name}}[0];
      $ascensions_for{$game{name}}[1] = $game{endtime};

      # calculate asc streaks here because who needs another pass over all games
      my $a = ++$ascstreak_for{$game{name}}[0];
      $ascstreak_for{$game{name}}[1] = $game{endtime};
      if (!exists($best_ascstreak_for{$game{name}}) || $a > $best_ascstreak_for{$game{name}}[0])
      {
        $best_ascstreak_for{$game{name}} = [$a, $game{endtime}];
      }
    }
    else
    {
      $ascstreak_for{$game{name}} = [0, 0];
    }

    $txt_output_for{$game{name}} = $html_output_for{$game{name}} = "";
    push @games, \%game;
    push @ascensions, \%game if $game{ascended};
  }
} # }}}

sub demunge_realtime # {{{
{
  my $seconds = shift;
  my $hours = int($seconds / 3600);
  $seconds %= 3600;
  my $minutes = int($seconds / 60);
  $seconds %= 60;
  return sprintf "%d:%02d:%02d", $hours, $minutes, $seconds;
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

sub trophy_output_begin # {{{
{
  my ($display, $short) = @_;

  open(my $txt_handle, '>', "trophy/$short.txt") or my_die "Unable to open trophy/$short.txt: $!";
  open(my $html_handle, '>', "trophy/$short.html") or my_die "Unable to open trophy/$short.html: $!";

  print {$txt_handle} $display, "\n";
  print {$html_handle} << "EOH4";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>The 2007 June nethack.alt.org Tournament - $display</title>
    <link rel="stylesheet" type="text/css" href="../trophy.css" />
  </head>
  <body>
    <h1>The 2007 June nethack.alt.org Tournament</h1>
    <h2>$display</h2>
    <h3>{{LASTTIME}}</h3>
    <ul id="mainlinks">
      <li><a href="$short.txt">plaintext version</a></li>
      <li><a href="../index.html">main page</a></li>
      <li><a href="../scoreboard.html">scoreboard</a></li>
      <li><a href="http://alt.org/nethack/">nethack.alt.org</a></li>
    </ul>
    <hr />
    <ol>
EOH4

  return ($txt_handle, $html_handle);
} # }}}

sub calc_generic_trophy # {{{
{
  my %player_info;

  # read arguments; tread lightly if you change this code {{{
  my $args = shift;

  my $display_name = $args->{name};

  my $reverse     = defined($args->{need_reverse}) ? $args->{need_reverse}  : 0;
  my $list        = defined($args->{list})         ? $args->{list} : \@ascensions;
  $list = $args->{list_sub}() if defined($args->{list_sub});

  my $trophy_stat = $args->{trophy_stat}   || "";
  my $get_name    = $args->{get_name}      || sub {$_[0]{name}};
  my $grep        = $args->{grep_callback} || undef;
  my $sorter      = $args->{sorter}        || undef;
  my $short       = $args->{short}         || $display_name;

  my $display_callback = $args->{display_callback} ||
  sub
  {
    my $g = shift;
    sprintf "{{%s}} - %s", $g->{name}, $g->{$trophy_stat};
  }; # }}}

  # how are we sorting? we need to maintain stability {{{
  if (!defined($sorter))
  {
    if ($reverse)
    {
      $sorter = sub {$b->{$trophy_stat} <=> $a->{$trophy_stat}};
    }
    else
    {
      $sorter = sub {$a->{$trophy_stat} <=> $b->{$trophy_stat}};
    }
  } # }}}

  # actually do the sorting, after we narrow down the list we want {{{
  my @sorted = @{$list};
  @sorted = $grep->(@sorted) if defined $grep;
  @sorted = grep { exists($_->{$trophy_stat}) } @sorted if $trophy_stat ne '';
  @sorted = sort $sorter @sorted;
  # }}}

  # print all output for this trophy {{{
  {
    my ($txt_handle, $html_handle) = trophy_output_begin($display_name, $short);

    foreach my $n (0..$#sorted)
    {
      # the callback surrounds nicks like "{{eidolos2}}" to let us know what
      # to link for the html version; in the text version we just remove the
      # markers

      my $callback_html = $display_callback->($sorted[$n]);
      my $callback_txt = $callback_html;
      $callback_txt =~ s/{{|}}//g;
      $callback_html =~ s!{{(.*)}}!<a href="../player/$1.html">$1</a>!g;
      my $clan_points = $n < @points_for_position ? int($args->{clan_points} * $points_for_position[$n]) : 0;
      $clan_points = $clan_points ? sprintf(' (%d point%s)', $clan_points, $clan_points == 1 ? '': 's') : '';
      printf {$txt_handle} "%d: %s%s\n", $n+1, $callback_txt, $clan_points;
      printf {$html_handle} "      <li>%s%s</li>\n", $callback_html, $clan_points;;
    }

    print {$html_handle} << "EOH5";
    </ol>
  </body>
</html>
EOH5
  } # }}}

  # go from index-by-gamenum to index-by-playername {{{
  foreach my $n (0..$#sorted)
  {
    my $name = $get_name->($sorted[$n]);
    push @{$player_info{$name}}, {num => $n, rank => $n};
  } # }}}

  # build up output for each player {{{
  foreach my $name (keys %txt_output_for)
  {
    my $num;
    my @nums = (0..2);
    my $clan_points = 0;
    my $indent = '';

    # does this player have any games eligible for this trophy?
    # if not we just display the top three
    if (exists($player_info{$name}))
    {
      $num = $player_info{$name}[0]{num};

      # add clan points -- this handles the player placing more than once
      # in the top N (where N = @points_for_position - 1, probably 3)
      for (my $n = 0; $n < @{$player_info{$name}} && $player_info{$name}[$n]{num} < @points_for_position; ++$n)
      {
        $clan_points += int($args->{clan_points} * $points_for_position[$player_info{$name}[$n]{num}]);
      }

      # display top N if sufficiently highly ranked
      # otherwise top 3 and 2 around
      if ($num < 7)
      {
        push @nums, 3 .. $num+2;
      }
      else
      {
        # the [] signals the "..."
        push @nums, [], $num-2 .. $num+2;
      }
    }

    # stop when we get to the lowest ranked player
    pop @nums while @nums && $nums[-1] >= @sorted;

    # add trophy name to output, with a placeholder for clan points
    $txt_output_for{$name} .= $display_name . "<<TROPHY_CLAN_POINTS>>:\n";
    $html_output_for{$name} .= "    <hr />\n    <h3><a href=\"../trophy/$short.html\">$display_name</a><<TROPHY_CLAN_POINTS>></h3><!-- type:$short -->\n";

    if (exists $txt_status{$short}{$name})
    {
      $txt_output_for{$name} .= $txt_status{$short}{$name};
      $txt_output_for{$name} .= "  Winners\n";
      $indent = '  ';
    }
    if (exists $html_status{$short}{$name})
    {
      $html_output_for{$name} .= $html_status{$short}{$name};
      $html_output_for{$name} .= "      <h4>Winners</h4>\n";
    }

    $html_output_for{$name} .= "    <ol class=\"trophy\">\n";

    # can't do a for (@nums) here because we need to look ahead
    foreach my $el (0..$#nums)
    {
      my $n = $nums[$el];
      if (ref($n))
      {
        $txt_output_for{$name} .= "$indent  ...\n";
        $html_output_for{$name} .= "    </ol>\n    <div class=\"ellipses\">...</div>\n    <ol class=\"trophy\" start=\"".(1+$nums[$el+1])."\">\n";
      }
      else
      {
        # the callback surrounds nicks like "{{eidolos2}}" to let us know what
        # to link for the html version; in the text version we just remove the
        # markers

        my $callback_html = $display_callback->($sorted[$n]);
        my $callback_txt = $callback_html;
        $callback_txt =~ s/{{|}}//g;

        my ($scorer) = $callback_html =~ /{{(.*)}}/;
        my $my_score = $scorer eq $name;

        if ($my_score)
        {
          # don't link to our own page
          $callback_html = $callback_txt;
        }
        else
        {
          if ($name eq '')
          {
            $callback_html =~ s!{{.*}}!<a href="player/$scorer.html">$scorer</a>!g;
          }
          else
          {
            $callback_html =~ s!{{.*}}!<a href="$scorer.html">$scorer</a>!g;
          }
        }

        $txt_output_for{$name} .= sprintf "%s%s %d: %s\n", $indent, $my_score ? "*" : " ", $n+1, $callback_txt;
        $html_output_for{$name} .= sprintf "      <li%s>%s</li>\n", $my_score ? " class=\"me\"" : "", $callback_html;
      }
    }

    $html_output_for{$name} .= "    </ol>\n";
    if (@sorted == 0)
    {
      $txt_output_for{$name} .= "$indent  (No current winner)\n";
      $html_output_for{$name} .= "    <div class=\"nogames\">(No current winner)</div>\n";
    }
    elsif (!exists($player_info{$name}) && $name ne '')
    {
      $txt_output_for{$name} .= "$indent  (No eligible games for $name)\n";
      $html_output_for{$name} .= "    <div class=\"nogames\">(No eligible games for $name)</div>\n";
    }
    $txt_output_for{$name} .= "\n";

    $clan_points_for{$name} += $clan_points if $clan_points && exists $clan_of{$name};

    # now fill in the clan point placeholders since we're done processing the
    # current player's games
    for ($txt_output_for{$name}, $html_output_for{$name})
    {
      s{<<TROPHY_CLAN_POINTS>>}
       {
         if (exists $clan_of{$name})
         {
           if ($clan_points > 0)
           {
             sprintf ' (%d point%s)',
                     $clan_points,
                     $clan_points == 1 ? '' : 's';
           }
           else
           {
             ''
           }
         }
         else
         {
           ''
         }
       }eg;
    }
  } # }}}
} # }}}

sub calc_achievement_trophies # {{{
{
  foreach my $player (keys %txt_output_for)
  {
    next if $player eq '';
    my ($best, $bestbell) = achievements_for($player);
    $achievement_for{$player} = [$best, $bestbell];
    push @{$achievements{$achievement_trophies[$bestbell]}},
      "$player (with bells on)"
        if $bestbell;
    push @{$achievements{$achievement_trophies[$best]}},
      $player
        if $best > $bestbell;
  }

  foreach my $trophy (keys %achievement_trophies)
  {
    my ($txt_handle, $html_handle) = trophy_output_begin($achievement_trophies{$trophy}, $trophy);

    if (exists $achievements{$trophy})
    {
      foreach my $player (sort {($b =~ / bells /) <=> ($a =~ / bells /)
                                                  ||
                                           lc($a) cmp lc($b)}
                               @{$achievements{$trophy}})
      {
        printf {$txt_handle} "%s\n", $player;
        printf {$html_handle} "      <li><a href=\"..player/%s.html\">%s</a></li>\n", $player, $player;
      }
      }

    print {$html_handle} << "EOH9";
    </ol>
  </body>
</html>
EOH9
  }
} # }}}

sub write_pages # {{{
{
  my $directory = 'player';
  my $extension = 'txt';
  my $post      = '';

  while (1)
  {
    my ($name, $output);

    # order is (player-txt, player-html, clan-txt, clan-html)
    if ($extension eq 'txt')
    {
      my $next_set = 0;
      if ($directory eq 'player')
      {
        ($name, $output) = each %txt_output_for or $next_set = 1;
      }
      else
      {
        ($name, $output) = each %clan_txt_output_for or $next_set = 1;
      }

      if ($next_set)
      {
        $extension = 'html';
        $post = "  </body><!-- type:post -->\n</html>\n";
      }
    }

    if ($extension eq 'html')
    {
      my $next_set = 0;
      if ($directory eq 'player')
      {
        ($name, $output) = each %html_output_for or $next_set = 1;
      }
      else
      {
        ($name, $output) = each %clan_html_output_for or $next_set = 1;
      }

      if ($next_set)
      {
        if ($directory eq 'clan')
        {
          last;
        }
        $directory = 'clan';
        $extension = 'txt';
        $post      = '';
        next;
      }
    }

    # last call to fill in any placeholders
    $output =~ s{<<CLAN_POINTS:(\w+)>>}
                {
                  if (exists $clan_of{$1})
                  {
                    if (exists $clan_points_for{$1})
                    {
                      sprintf ' (%d point%s)',
                              $clan_points_for{$1},
                              $clan_points_for{$1} == 1 ? '' : 's';
                    }
                    else
                    {
                      ""
                    }
                  }
                  else
                  {
                    ""
                  }
                }eg;

    my $handle;
    if ($name eq '')
    {
      open($handle, ">", "scoreboard.$extension") or warn "Unable to open scoreboard.$extension: $!";
      $output =~ s{../trophy}{trophy}g;
      $output =~ s{../player}{player}g;
      $output =~ s{../clan}  {clan}g;
    }
    else
    {
      open($handle, ">", "$directory/$name.$extension") or warn "Unable to open $directory/$name.$extension: $!";
    }

    print {$handle} $output, $post;
    close $handle;
  }
} # }}}

sub earned_bell # {{{
{
  my $player  = shift;
  my $bell    = shift;
  my $succeed = 0;
  my %roles;
  my %races;
  my %genders;
  my %aligns;
  my %conducts;

  foreach my $game_ref (@{$games_for{$player}})
  {
    goto clear unless $game_ref->{ascended};
    goto clear if $genders{$game_ref->{gender0}}++ && $bell == 4;
    goto clear if $aligns{$game_ref->{align0}}++   && $bell == 5;
    goto clear if $races{$game_ref->{race}}++      && $bell == 6;
    goto clear if $roles{$game_ref->{role}}++      && $bell == 7;

    my $newconduct = 0;
    foreach my $conduct (demunge_conduct($game_ref->{conduct}))
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
    next unless $game_ref->{ascended};
    ++$roles{$game_ref->{role}};
    ++$races{$game_ref->{race}};
    ++$genders{$game_ref->{gender0}};
    ++$aligns{$game_ref->{align0}};
    ++$conducts{$_} for (demunge_conduct($game_ref->{conduct}));
  }

  return 0;
} # }}}

sub achievements_for # {{{
{
  my $player = shift;
  my ($best, $bestbell) = (0, 0);

  my %roles;
  my %races;
  my %genders;
  my %aligns;
  my %conducts;

  for my $game_ref (@{$games_for{$player}})
  {
    $best = 1 if $game_ref->{deathlev} < 0 && $game_ref->{deathlev} > -6 && $best < 1;
    $best = 2 if $game_ref->{deathlev} == -5 && $best < 2;
    next unless $game_ref->{ascended};
    $best = 3;

    ++$roles{$game_ref->{role}};
    ++$races{$game_ref->{race}};
    ++$genders{$game_ref->{gender0}};
    ++$aligns{$game_ref->{align0}};
    ++$conducts{$_} for demunge_conduct($game_ref->{conduct});
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
} # }}}

sub b13_for # {{{
{
  my $player = shift;
  my $best = 0;
  my $best_end = 0;
  my $last = 0;
  my $last_start = 0;

  foreach my $start (0..$#{$games_for{$player}})
  {
    my $cur = 0;
    my $end = 0;
    my %seen = ();
    for (my $num = $start; $num < $start + 13 && $num < @{$games_for{$player}}; ++$num)
    {
      my $game_ref = $games_for{$player}[$num];
      last unless defined $game_ref;
      next unless $game_ref->{ascended};
      last if $seen{$game_ref->{crga0}}++;
      ++$cur;
      $end = $game_ref->{endtime};
    }
    ($best, $best_end) = ($cur, $end) if $cur > $best;
    ($last, $last_start) = ($cur, $start) if $cur > $last;
  }

  my $cur_start = @{$games_for{$player}} - 13;
  $cur_start = 0 if $cur_start < 0;

  my @type = ([$last_start, "Best"], [$cur_start, "Current"]);

  foreach (@type)
  {
    my $ascs = 0;
    $html_status{b13}{$player} .= "      <h4>$_->[1] (<<CURRENT_B13>>)</h4>\n";
    $html_status{b13}{$player} .= "      <ol>\n";
    $txt_status{b13}{$player} .= "  $_->[1] (<<CURRENT_B13>>)\n";

    my %seen;
    for my $num ($_->[0]..$_->[0]+12)
    {
      my $game_ref = $games_for{$player}[$num];
      last unless defined $game_ref;
      if (!$game_ref->{ascended})
      {
        $html_status{b13}{$player} .= "        <li class=\"b13 death\">died</li>\n";
        $txt_status{b13}{$player} .= sprintf "    %d. %s\n", 1+$num-$_->[0], "died";
        next;
      }
      if ($seen{$game_ref->{crga0}}++)
      {
        $html_status{b13}{$player} .= "        <li class=\"b13 repeat\">$game_ref->{crga0} (repeated)</li>\n";
        $txt_status{b13}{$player} .= sprintf "    %d. %s (repeated)\n", 1+$num-$_->[0], $game_ref->{crga0};
        last;
      }
      ++$ascs;
      $html_status{b13}{$player} .= "        <li class=\"b13 ascend\">$game_ref->{crga0}</li>\n";
      $txt_status{b13}{$player} .= sprintf "    %d. %s\n", 1+$num-$_->[0], $game_ref->{crga0};
    }

    $html_status{b13}{$player} .= "      </ol>\n";
    $txt_status{b13}{$player} .= "\n";
    $html_status{b13}{$player} =~ s/<<CURRENT_B13>>/$ascs/g;
    $txt_status{b13}{$player} =~ s/<<CURRENT_B13>>/$ascs/g;
  }
  return ($best, $best_end);
} # }}}

sub best_of_13 # {{{
{
  [ map { [ $_, b13_for($_) ] } keys %ascensions_for ]
} # }}}

sub main # {{{
{
  print "Reading clan_info\n";
  read_clan_info("clan_info");
  print "Reading xlogfile\n";
  read_xlogfile("xlogfile", "xlogfile.unsure");

# read_xlogfile populates %txt_output_for's keys with each player
# so we put any initial text for each player's page here
  foreach my $name (keys %txt_output_for) # {{{
  {
    my $asc = exists($ascensions_for{$name}) ? $ascensions_for{$name}[0] : 0;
    my $clan_info = "Clan: none!\n";

    if (exists $clan_of{$name})
    {
      $clan_info = "Clan: $clan_of{$name}<<CLAN_POINTS:$name>>\n  Clan mates:\n" .
                   join '',
                   map { "    $_<<CLAN_POINTS:$_>>\n" }
                   sort
                   keys %{$clan_roster{ $clan_of{$name} }};
    }

    $txt_output_for{$name}  = sprintf "Player: %s\nAscensions: %d/%d (%.2f%%)\n%s\n", $name, $asc, scalar @{$games_for{$name}}, 100*$asc/@{$games_for{$name}}, $clan_info;
    $txt_output_for{$name} .= sprintf "Ascensions without dumplogs: %d\n  Email Eidolos if this persists for more than 24 hours.\n", $unsure_for{$name} if exists($unsure_for{$name}) && $unsure_for{$name};
    $txt_output_for{$name} .= "{{LASTTIME}}\n";

    # html output
    $clan_info = exists $clan_of{$name} ? "<h2>Clan: $clan_of{$name}<<CLAN_POINTS:$name>></h2>\n"
                                        : "<h2>Clan: <em>none!</em></h2>\n";

    my $unsure_info = "";
    if (exists $unsure_for{$name} && $unsure_for{$name})
    {
      $unsure_info = sprintf '      <h2>Ascensions without dumplogs: %d</h2>%s',
                     $unsure_for{$name},
                     "\n";
      $unsure_info .= "      <h2>Email Eidolos if this persists for more than 24 hours.</h2>\n";
    }

    my $format_string = << "EOH";
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html>
    <head>
      <title>The 2007 June nethack.alt.org Tournament - %s</title>
      <link rel="stylesheet" type="text/css" href="../player.css" />
    </head>
    <body>
      <h1>The 2007 June nethack.alt.org Tournament - %s</h1>
      <h2>Ascensions: %d/%d (%.2f%%)</h2>
      %s%s
      <h3>{{LASTTIME}}</h3>
      <ul id="mainlinks">
        <li><a href="%s.txt">plaintext version</a></li>
        <li><a href="../index.html">main page</a></li>
        <li><a href="../scoreboard.html">scoreboard</a></li>
        <li><a href="http://alt.org/nethack/">nethack.alt.org</a></li>
      </ul>
EOH

    $html_output_for{$name} = sprintf $format_string, $name, $name, $asc, scalar @{$games_for{$name}}, 100*$asc/@{$games_for{$name}}, $unsure_info, $clan_info, $name;

    if (exists $clan_of{$name})
    {
      my $format_string = << "EOH2";
      <hr />
      <h3>Members of <a href=\"../clan/%s.html\">%s</a></h3>
      <ul id="clanmates">
  %s
      </ul>
EOH2

      my $mates = join "\n",
                  map
                  {
                    $_ eq $name ? "      <li class=\"me\">$_<<CLAN_POINTS:$_>></li>"
                                : "      <li><a href=\"$_.html\">$_</a><<CLAN_POINTS:$_>></li>"
                  }
                  sort
                  keys %{$clan_roster{ $clan_of{$name} }};
      $html_output_for{$name} .= sprintf $format_string, $clan_of{$name}, $clan_of{$name}, $mates;
    }
    else
    {
      # might add a "join a clan, doofus!" message
    }
  } # }}}

# read_clan_info populates %clan_txt_output_for's keys with each clan
# so we put any initial text for each clan's page here
  foreach my $clan (keys %clan_txt_output_for) # {{{
  {
    my $roster = join '',
                 map { "  $_<<CLAN_POINTS:$_>>\n" }
                 sort
                 keys %{$clan_roster{$clan}};
    $clan_txt_output_for{$clan} = sprintf "Clan: %s\nAscensions: %d/%d (%.2f%%)\n\nRoster:\n%s\n", $clan, $clan_ascs{$clan} || 0, $clan_games{$clan} || 0, $clan_games{$clan} ? 100*$clan_ascs{$clan}/$clan_games{$clan} : 0, $roster;
  } # }}}

  $txt_output_for{''} = "Current standings:\n";
  $html_output_for{''} = << 'EOH8';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
  <title>The 2007 June nethack.alt.org Tournament Scoreboard</title>
  <link rel="stylesheet" type="text/css" href="player.css" />
</head>
<body>
  <h1>The 2007 June nethack.alt.org Tournament Scoreboard</h1>
  <h3>{{LASTTIME}}</h3>
  <ul id="mainlinks">
    <li><a href="scoreboard.txt">plaintext version</a></li>
    <li><a href="index.html">main page</a></li>
    <li><a href="http://alt.org/nethack/">nethack.alt.org</a></li>
  </ul>
EOH8

# prefer data structures to code
  my @trophies = # {{{
  (
    {
      name             => "Best of 13",
      short            => "b13",
      clan_points      => 10,
      list_sub         => \&best_of_13,
      sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
      get_name         => sub { $_[0][0] },
      display_callback => sub {my $b13 = shift; sprintf "{{%s}} - %d", $b13->[0], $b13->[1]}
    },
    {
      name             => "Most ascensions",
      short            => "mostascs",
      clan_points      => 9,
      list_sub         => sub {[map {[$_, @{$ascensions_for{$_}}]} keys %ascensions_for]},
      sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
      get_name         => sub { $_[0][0] },
      display_callback => sub {my $ma = shift; sprintf "{{%s}} - %d", $ma->[0], $ma->[1]}
    },
    {
      name             => "Longest ascension streak",
      short            => "ascstreak",
      clan_points      => 9,
      list_sub         => sub {[map {[$_, @{$best_ascstreak_for{$_}}]} keys %best_ascstreak_for]},
      sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
      get_name         => sub { $_[0][0] },
      display_callback => sub {my $ma = shift; sprintf "{{%s}} - %d", $ma->[0], $ma->[1]}
    },
    {
      name             => "First ascension",
      short            => "first",
      clan_points      => 6,
      trophy_stat      => "endtime",
      display_callback => sub
      {
        my $g = shift;
        if ($devnull)
        {
          my $time = gmtime($g->{endtime} - 8 * 3600);
          $time =~ s/  / /;
          sprintf "{{%s}} - #%d (%s)", $g->{name}, $g->{num}, $time
        }
        else
        {
          sprintf "{{%s}} - #%d", $g->{name}, $g->{num};
        }
      },
    },
    {
      name             => "Fastest ascension",
      short            => "fastest",
      clan_points      => 8,
      trophy_stat      => "turns",
      display_callback => sub {my $g = shift; sprintf "{{%s}} - T:%d", $g->{name}, $g->{turns}}
    },
    {
      name             => "Quickest ascension",
      short            => "quickest",
      clan_points      => 8,
      trophy_stat      => "realtime",
      display_callback => sub {my $g = shift; sprintf "{{%s}} - %s", $g->{name}, demunge_realtime($g->{realtime})}
    },
    {
      name             => "Best behaved ascension",
      short            => "conduct",
      clan_points      => 7,
      trophy_stat      => "conducts",
      need_reverse     => 1,
      display_callback => sub {my $g = shift; sprintf "{{%s}} - %d: %s", $g->{name}, $g->{conducts}, (join ', ', demunge_conduct($g->{conduct})) || "(none)"}
    },
    {
      name             => "Most extinctionist ascension",
      short            => "extinctionist",
      clan_points      => 5,
      trophy_stat      => "kills",
      need_reverse     => 1,
      display_callback => sub {my $g = shift; sprintf "{{%s}} - %d kill%s", $g->{name}, $g->{kills}, $g->{kills} == 1 ? "" : "s"}
    },
    {
      name             => "Truest pacifist ascension",
      short            => "pacifistest",
      clan_points      => 5,
      trophy_stat      => "kills",
      needs_reverse    => 1,
      display_callback => sub {my $g = shift; sprintf "{{%s}} - %d kill%s", $g->{name}, $g->{kills}, $g->{kills} == 1 ? "" : "s"}
    },
    {
      name             => "Richest ascension",
      short            => "richest",
      clan_points      => 5,
      trophy_stat      => "gold",
      need_reverse     => 1,
      display_callback => sub {my $g = shift; sprintf "{{%s}} - \$%d", $g->{name}, $g->{gold}}
    },
    {
      name             => "Low-scoring ascension",
      short            => "lsa",
      clan_points      => 7,
      trophy_stat      => "points",
      display_callback => sub {my $g = shift; sprintf "{{%s}} - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
    },
    {
      name             => "High-scoring ascension",
      short            => "highasc",
      clan_points      => 5,
      trophy_stat      => "points",
      need_reverse     => 1,
      display_callback => sub {my $g = shift; sprintf "{{%s}} - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
    },
  );

  foreach my $role (@roles)
  {
    push @trophies,
    {
      name             => "High-scoring $expand{$role}",
      short            => "high\l$role",
      clan_points      => 2,
      list             => \@games,
      trophy_stat      => "points",
      need_reverse     => 1,
      grep_callback    => sub {grep {$_->{role} eq $role} @_},
      display_callback => sub {my $g = shift; $|++; sprintf "{{%s}} - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
    };
  } # }}}

  foreach my $trophy_ref (@trophies)
  {
    print "Processing $trophy_ref->{name}\n";
    calc_generic_trophy($trophy_ref);
  }

  print "Processing achievement trophies\n";
  calc_achievement_trophies();

  print "Printing player and clan pages\n";
  write_pages();

# print player.html, player.txt # {{{
  {
    open(my $player_html, '>', 'players.html') or my_die "Unable to open players.html for writing: $!";
    open(my $player_txt, '>', 'players.txt') or my_die "Unable to open players.txt for writing: $!";

    print {$player_html} << "EOH6";
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html>
      <head>
        <title>The 2007 June nethack.alt.org Tournament Players</title>
        <link rel="stylesheet" type="text/css" href="trophy.css" />
      </head>
      <body>
        <h1>The 2007 June nethack.alt.org Tournament Players</h1>
        <h3>{{LASTTIME}}</h3>
        <ul id="mainlinks">
          <li><a href="players.txt">plaintext version</a></li>
          <li><a href="index.html">main page</a></li>
          <li><a href="scoreboard.html">scoreboard</a></li>
          <li><a href="http://alt.org/nethack/">nethack.alt.org</a></li>
        </ul>
        <hr />
        <ul>
EOH6

    for (sort keys %txt_output_for)
    {
      next if $_ eq '';
      printf {$player_html} '      <li><a href="player/%s.html">%s</a> <a href="player/%s.txt">(plaintext)</a>%s</li>%s', $_, $_, $_, exists $clan_of{$_} ? sprintf(' of <a href="clan/%s.html">clan %s</a>', $clan_of{$_}, $clan_of{$_}) : "", "\n";
      printf {$player_txt} '%s%s%s', $_, exists $clan_of{$_} ? " of clan $clan_of{$_}" : "", "\n";
    }

    print {$player_html} << "EOH7";
        </ul>
      </body>
    </html>
EOH7
  } # }}}
} # }}}

main();

unlink ".lock";

