#!/usr/bin/perl
use strict;
use warnings;

# Global variables {{{
my $devnull = 1; # devnull uses a slightly different logfile format versus June

# use more 'ram'; use less 'time'; :)
my @games;       # contains *all* games
my @ascensions;  # contains *all* ascensions
my %games_for;
my %ascensions_for;
my %unsure_for;  # how many "unsure" (dumplogless) games for player?
my %achievements; # keyed by achievement name, list of players with that ach.
my %achievement_for; # keyed by player name, lists their bells/nonbells
my %clan_games;
my %clan_ascs;
my %best_ascstreak_for; # this is the only trophy not calculated with the rest
                        # for efficiency
my %clan_of;
my %clan_roster; # a hash of array refs, $clan_roster{clan} = [members]
my %clan_points_for;
my %txt_output_for;
my %html_output_for;
my %clan_txt_output_for;
my %clan_html_output_for;
my %html_status; # this is for aux information; $html_status{player}{trophy}
my %txt_status; # same
# }}}

# Constants {{{
# what % of points the person in position n gets
my @points_for_position = (1.00, .60, .30);

my @roles = qw{Arc Bar Cav Hea Kni Mon Pri Ran Rog Sam Tou Val Wiz};

my @conducts = qw{foodless vegan vegetarian atheist weaponless pacifist illiterate polyitemless polyselfless wishless artiwishless genoless};

my @achievement_trophies = qw(none gold platinum dilithium birdie doubletop hattrick grandslam fullmonty);

my %achievement_trophies =
(
# short     => 'display',
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
  # used instead of die to populate the .lock file with a stacktrace
  # argument(s): textual description of what went wrong

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
  # sets up clans given by files
  # argument(s): clan info file(s)

  local @ARGV = @_;

  # each line consists of a playername:clanname
  while (<>)
  {
    chomp;
    my ($nick, $clan) = split /:/, $_, 2;
    next unless $nick && $clan;

    $clan_of{$nick} = $clan;
    $clan_roster{$clan}{$nick} = 1;
    $clan_txt_output_for{$clan} = $clan_html_output_for{$clan} = "";
  }
} # }}}

sub read_xlogfile # {{{
{
  # reads the files passed to it and populates most of the global variables
  # with game information
  # argument(s): xlogfile(s)

  local @ARGV = @_;

  my %seen;
  my %ascstreak_for;
  my $num = 0;

  while (<>)
  {
    my %game;

    if ($devnull)
    {
      # devnull uses a unique ID at the start of each logfile to determine
      # whether the game is a repeat or not
      s/^(\S+ )//;
      next if $seen{$1}++;
    }

    chomp;

    # parse the xlogfile.. so much better than NH's logfile!
    foreach (split /:/, $_)
    {
      next unless /^([^=]+)=(.*)$/;
      $game{$1} = $2;
    }

    next if $game{death} eq "a trickery";

    if ($devnull)
    {
      # the June tournament sets these fields in the xlogfile
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
  # converts seconds to "h:mm:ss"
  my $seconds = shift;
  my $hours = int($seconds / 3600);
  $seconds %= 3600;
  my $minutes = int($seconds / 60);
  $seconds %= 60;
  return sprintf "%d:%02d:%02d", $hours, $minutes, $seconds;
} # }}}

sub demunge_conduct # {{{
{
  # the xlogfile format uses a bitfield for conducts, stored as hexadecimal
  # argument: the hexadecimal(!) bitstring
  # returns: a list of plaintext achieved conduct names

  my $conduct = hex($_[0]);
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
  # prints the long header for a trophy's output file
  # arguments: the display name ("Best of 13") and short name ("b13")
  # returns: a handle to the txt output, a handle to the html output

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

sub generic_trophy # {{{
{
  # this too-large function calculates all the information for the given trophy
  # arguments: a hash ref containing a few fields, most of which are optional:
  #   name: the full name of the trophy ("Best of 13")
  #   short: the "short" name of the trophy ("b13" to "Best of 13")
  #   list: an arrayref of hashrefs containing game information (default: list
  #         of ascensions)
  #   list_sub: a coderef that, when called, will produce list
  #   grep: use this to filter just the games you want (such as only wizards for
  #         "high scoring wizard" trophy)
  #   sorter: a coderef that is used to sort games to determine who's winning
  #           the trophy
  #   trophy_stat: if the trophy is for a single stat (such as turns) you can
  #                set this instead of writing a sorter
  #   needs_reverse: a boolean that, if true, will sort the list into descending
  #                  order (only for use with trophy_stat, not sorter)
  #   get_name: a coderef that extracts the player name from one element of list
  #   display_callback: a coderef that is used to stringify one game for the
  #                     trophy (so Fastest Asc might display turns, but Richest
  #                     wouldn't)

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

    # add trophy name to output, with a placeholder for clan points (since this
    # loop iterates over each game -- if a player places more than once the
    # first-place finish will not have the second-place points in time)
    $txt_output_for{$name} .= $display_name . "<<TROPHY_CLAN_POINTS>>:\n";
    $html_output_for{$name} .= "    <hr />\n    <h3><a href=\"../trophy/$short.html\">$display_name</a><<TROPHY_CLAN_POINTS>></h3><!-- type:$short -->\n";

    # add auxiliary info if it exists (such as the breakdown for b13)
    if (exists $txt_status{$short}{$name})
    {
      $txt_output_for{$name} .= $txt_status{$short}{$name};
      $txt_output_for{$name} .= "  Winners\n";
      $indent .= '  ';
    }
    if (exists $html_status{$short}{$name})
    {
      $html_output_for{$name} .= $html_status{$short}{$name};
      $html_output_for{$name} .= "      <h4>Winners</h4>\n";
    }

    $html_output_for{$name} .= "    <ol class=\"trophy\">\n";

    # add the top/around winners to this player's files
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
          if ($name eq '') # true when we're printing the overall scoreboard
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

    # now print out the tail end of this trophy
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

sub achievement_trophies # {{{
{
  # this calculates trophies like "Grand Slam" which don't fit well with the
  # generic trophy code
  # arguments: none

  # calculate achievement trophies {{{
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
  } # }}}

  # print each trophy file {{{
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
        if ($player =~ /^(.+) \(with bells on\)$/)
        {
          printf {$html_handle} "      <li><a href=\"..player/%s.html\">%s (with bells on)</a></li>\n", $1, $1;
        }
        else
        {
          printf {$html_handle} "      <li><a href=\"..player/%s.html\">%s</a></li>\n", $player, $player;
        }
      }
    }

    print {$html_handle} << "EOH9";
    </ol>
  </body>
</html>
EOH9
  } # }}}

  # add each trophy to each player's output {{{
  foreach my $name (keys %txt_output_for)
  {
    my ($best, $bestbell) = exists $achievement_for{$name} ? @{ $achievement_for{$name} } : (0, 0);
    foreach (reverse (1..$#achievement_trophies))
    {
      my $indent = '';
      my $short = $achievement_trophies[$_];
      my $display_name = $achievement_trophies{$short};

      $txt_output_for{$name} .= "$display_name:\n";

      # auxiliary info (like what else the player needs to get this trophy)
      if (exists $txt_status{$short}{$name})
      {
        $txt_output_for{$name} .= $txt_status{$short}{$name};
        $txt_output_for{$name} .= "  Winners\n";
        $indent = '  ';
      }

      if (!exists $achievements{$short} || !@{$achievements{$short}})
      {
        $txt_output_for{$name} .= "$indent  (No current winner)\n\n";
        next;
      }

      foreach my $output (sort {($b =~ / bells /) <=> ($a =~ / bells /)
                                                  ||
                                           lc($a) cmp lc($b)}
                               @{$achievements{$short}})
      {
        (my $player = $output) =~ s/ \(with bells on\)$//;
        $txt_output_for{$name} .= sprintf "%s%s %s\n", $indent, $player eq $name ? "*" : " ", $output;
      }

      $txt_output_for{$name} .= "\n";
    }
  } # }}}
} # }}}

sub write_pages # {{{
{
  # goes through the *_output_for data structures and writes them to disk
  # arguments: none

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
    if ($name eq '') # scoreboard?
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
  # auxiliary function to determine whether a player has earned a certain bell
  # arguments: player name, bell number
  # returns: 1 if player got that bell, 0 otherwise

  my ($player, $bell) = @_;
  my (%roles, %races, %genders, %aligns, %conducts);

  # try starting from each game to see if the player has the bell starting there
  START: foreach my $start (0..$#{$games_for{$player}})
  {
    # at this point we haven't ascended anything, so make sure the structures
    # are empty
    %roles = %races = %genders = %aligns = %conducts = ();
    next unless $games_for{$player}[$start]{ascended};

    # start iterating over the rest of the games
    foreach my $num ($start..$#{$games_for{$player}})
    {
      my $game_ref = $games_for{$player}[$num];

      # if this game duplicates what we already have, then we have to start
      # over TODO: set $start to $num
      next START unless $game_ref->{ascended};
      next START if $genders{$game_ref->{gender0}}++ && $bell == 4;
      next START if $aligns{$game_ref->{align0}}++   && $bell == 5;
      next START if $races{$game_ref->{race}}++      && $bell == 6;
      next START if $roles{$game_ref->{role}}++      && $bell == 7;

      my $newconduct = 0;
      foreach my $conduct (demunge_conduct($game_ref->{conduct}))
      {
        ++$newconduct unless $conducts{$conduct}++;
      }
      next START if !$newconduct && $bell == 8;

      # game counts toward the current bell, let's see if we meet all criteria
      next if $bell >= 4 && keys(%genders)  < 2;
      next if $bell >= 5 && keys(%aligns)   < 3;
      next if $bell >= 6 && keys(%races)    < 5;
      next if $bell >= 7 && keys(%roles)    < 13;
      next if $bell >= 8 && keys(%conducts) < 12;
      return 1; # got the bell!
    }
  }

  # at this point we definitely do not have the bell, but we can help the player
  # in figuring out what he still needs to ascend to get the bell
  # note we use the data structures from before so don't clear them

  my @full = (undef, undef, undef, undef,
              {Mal => 1, Fem => 1},
              {Cha => 1, Neu => 1, Law => 1},
              {Hum => 1, Orc => 1, Elf => 1, Dwa => 1, Gno => 1},
              { map { $_ => 1 } @roles },
              { map { $_ => 1 } @conducts });

  my @best_fields = (undef, undef, undef, undef, \%genders, \%aligns, \%races, \%roles, \%conducts);

  # go through and delete from @full what we already have
  for my $t (4..$bell) { delete $full[$t]{$_} for (keys %{$best_fields[$t]}) }

  # if we have foodless or wishless, don't remind the user that they also have
  # the lesser conducts
  delete $full[8]{vegan} if exists $full[8]{foodless};
  delete $full[8]{vegetarian} if exists $full[8]{foodless} || exists $full[8]{vegan};
  delete $full[8]{artiwishless} if exists $full[8]{wishless};

  my $short = $achievement_trophies[$bell];

  $txt_status{$short}{$player} = "  For bells, need to ascend:\n" ;
  for (4..$bell)
  {
    my $x = join ', ', sort keys %{$full[$_]};
    $txt_status{$short}{$player} .= "    $x\n" if $x;
  }

  return 0;
} # }}}

sub achievements_for # {{{
{
  # argument: player name
  # returns: best nonbell achievement number, best bell achievement number

  my ($player) = @_;
  my ($best, $bestbell) = (0, 0);

  my (%roles, %races, %genders, %aligns, %conducts);

  # iterate over player's games to figure out what he has achieved {{{
  for my $game_ref (@{$games_for{$player}})
  {
    # did player make it to the Elemental Planes?
    $best = 1 if $game_ref->{deathlev} < 0 && $game_ref->{deathlev} > -6 && $best < 1;
    # did player make it to Astral?
    $best = 2 if $game_ref->{deathlev} == -5 && $best < 2;

    next unless $game_ref->{ascended};
    $best = 3;

    # player ascended, so add all his stats to the structures
    ++$roles{$game_ref->{role}};
    ++$races{$game_ref->{race}};
    ++$genders{$game_ref->{gender0}};
    ++$aligns{$game_ref->{align0}};
    ++$conducts{$_} for demunge_conduct($game_ref->{conduct});
  } # }}}

  # use the structures to bump up the best achievement {{{
  if ($best == 3)
  {{
                last if keys(%genders)  < 2;
     $best = 4, last if keys(%aligns)   < 3;
     $best = 5, last if keys(%races)    < 5;
     $best = 6, last if keys(%roles)    < 13;
     $best = 7, last if keys(%conducts) < 12;
     $best = 8;
  }} # }}}

  # figure out if the player has any bells {{{
  # the only reason we calculate over all possible bells is to populate the
  # auxiliary info with what the player needs to get that bell
  for (4..8)
  {
    $bestbell = $_ if earned_bell($player, $_);
  }

  # don't display what the player needs for trophies he already attained :)
  for (4..$bestbell)
  {
    delete $txt_status{ $achievement_trophies[$_] }{$player};
  } # }}}

  my @full = (undef, undef, undef, undef,
              {Mal => 1, Fem => 1},
              {Cha => 1, Neu => 1, Law => 1},
              {Hum => 1, Orc => 1, Elf => 1, Dwa => 1, Gno => 1},
              { map { $_ => 1 } @roles },
              { map { $_ => 1 } @conducts });

  my @best_fields = (undef, undef, undef, undef, \%genders, \%aligns, \%races, \%roles, \%conducts);

  # go through and delete from @full what we already have
  for my $t ($best+1..8) { delete $full[$t]{$_} for (keys %{$best_fields[$t]}) }

  # if we have foodless or wishless, don't remind the user that they also have
  # the lesser conducts
  delete $full[8]{vegan} if exists $full[8]{foodless};
  delete $full[8]{vegetarian} if exists $full[8]{foodless} || exists $full[8]{vegan};
  delete $full[8]{artiwishless} if exists $full[8]{wishless};

  # build up the output for each achievement trophy player lacks
  for my $b ($best+1..8)
  {
    my $short = $achievement_trophies[$b];

    $txt_status{$short}{$player} .= "  Need to ascend:\n" ;
    for ($best+1..$b)
    {
      my $x = join ', ', sort keys %{$full[$_]};
      $txt_status{$short}{$player} .= "    $x\n" if $x;
    }
  }

  return ($best, $bestbell);
} # }}}

sub b13_for # {{{
{
  # calculates the best of 13 for a single player
  # argument: player name
  # returns: the number of ascensions, game number of last ascension (for ties)

  my ($player) = @_;
  my ($best, $best_end) = 0;
  my ($last, $last_start) = 0; # for aux info

  # try starting from each game {{{
  foreach my $start (0..$#{$games_for{$player}})
  {
    my ($cur, $end) = 0;
    my %seen = ();

    # check the next 13 games
    for (my $num = $start; $num < $start + 13 && $num < @{$games_for{$player}}; ++$num)
    {
      my $game_ref = $games_for{$player}[$num];
      last unless defined $game_ref;

      # nonascensions don't hurt, but each takes up one of your 13
      next unless $game_ref->{ascended};

      # b13 forbids duplications
      last if $seen{$game_ref->{crga0}}++;

      # what we have is good
      ++$cur;
      $end = $game_ref->{endtime};
    }

    # does this beat our best?
    ($best, $best_end) = ($cur, $end) if $cur > $best;
    ($last, $last_start) = ($cur, $start) if $cur > $last;
  } # }}}

  # Build up auxiliary info {{{
  my $cur_start = @{$games_for{$player}} - 13;
  $cur_start = 0 if $cur_start < 0;

  # use last_start instead of best_end because we don't need to display all 13
  foreach ([$last_start, "Best"],
           [$cur_start,  "Current"])
  {
    my $ascs = 0;
    $html_status{b13}{$player} .= "      <h4>$_->[1] (<<CURRENT_B13>>)</h4>\n";
    $html_status{b13}{$player} .= "      <ol>\n";
    $txt_status{b13}{$player} .= "  $_->[1] (<<CURRENT_B13>>)\n";

    my %seen;

    # iterate over each game in the 13 to display it # {{{
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
    } # }}}

    $html_status{b13}{$player} .= "      </ol>\n";
    $txt_status{b13}{$player} .= "\n";
    $html_status{b13}{$player} =~ s/<<CURRENT_B13>>/$ascs/g;
    $txt_status{b13}{$player} =~ s/<<CURRENT_B13>>/$ascs/g;
  } # }}}

  return ($best, $best_end);
} # }}}

sub best_of_13 # {{{
{
  [ map { [ $_, b13_for($_) ] } keys %ascensions_for ]
} # }}}

sub main # {{{
{
  # check and update some tourney files {{{
# if some error occurred, there'll be a .lock file
# stop autoupdating if there's a .lock since information might be lost otherwise
  die "$0: I refuse to run, there's a .lock file." if -e ".lock";

# when all goes well we will remove the .lock (this is in case the script
# unexpectedly dies)
  system('touch .lock');

# .trophy_time is used only for its mtime, determining how long until the next
# update, and whether we need to rerun this script if doing a full update
  system('touch .trophy_time');
  # }}}

  # read all the relevant logfiles {{{
  print "Reading clan_info\n";
  read_clan_info("clan_info");
  print "Reading xlogfile\n";
  read_xlogfile($devnull ? "xlogfile.devnull" : ("xlogfile","xlogfile.unsure"));
  # }}}

# generate initial text for each player's page {{{
  foreach my $name (keys %txt_output_for)
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

# generate initial text for each clan's page {{{
  foreach my $clan (keys %clan_txt_output_for)
  {
    my $roster = join '',
                 map { "  $_<<CLAN_POINTS:$_>>\n" }
                 sort
                 keys %{$clan_roster{$clan}};
    $clan_txt_output_for{$clan} = sprintf "Clan: %s\nAscensions: %d/%d (%.2f%%)\n\nRoster:\n%s\n", $clan, $clan_ascs{$clan} || 0, $clan_games{$clan} || 0, $clan_games{$clan} ? 100*$clan_ascs{$clan}/$clan_games{$clan} : 0, $roster;
  } # }}}

  # generate initial text for the scoreboard {{{
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
  # }}}

# the entire list of generic trophies {{{
  my @trophies = 
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

  # handle each trophy {{{
  foreach my $trophy_ref (@trophies)
  {
    print "Processing $trophy_ref->{name}\n";
    generic_trophy($trophy_ref);
  }

  print "Processing achievement trophies\n";
  achievement_trophies();
  # }}}

  print "Printing player and clan pages\n";
  write_pages();

# print list of players to player.html, player.txt # {{{
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

