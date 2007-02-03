#!/usr/bin/perl
use strict;
use warnings;

my @games;
my @ascensions;
my %games_for;
my %ascensions_for;
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
my %all_fields;
my %html_status;
my %txt_status;

# some constants
my @points_for_position = (1.00, .60, .30);
my @roles = qw{Arc Bar Cav Hea Kni Mon Pri Ran Rog Sam Tou Val Wiz};
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

sub read_clan_info
{
  local @ARGV = @_;

  while (<>)
  {
    chomp;
    my ($nick, $clan) = split ':' or last;
    $clan_of{$nick} = $clan;
    $clan_roster{$clan}{$nick} = 1;
    $clan_txt_output_for{$clan} = $clan_html_output_for{$clan} = "";
  }
}

sub read_xlogfile
{
  my %seen;
  my %ascstreak_for;
  my $num = 0;

  local @ARGV = @_;

  while (<>)
  {
    my %game;

    # <devnull only>
    s/^(\S+ )//;
    next if $seen{$1}++;
    # </devnull only>

    chomp;
    ++$num;

    # parse the logfile.. ahh I love aardvarkj
    foreach (split /:/, $_)
    {
      next unless /^([^=]+)=(.*)$/;
      $game{$1} = $2;
    }

    next if $game{death} eq "a trickery";

    # add a few more fields
    $game{ascended} = $game{death} eq 'ascended' ? 1 : 0;
    $game{conducts} = scalar demunge_conduct($game{conduct});
    $game{num}      = $num;
    $game{crga0}    = join ' ', @game{qw/role race gender0 align0/};

    foreach (keys %game)
    {
      $all_fields{$_} = 1;
    }

    ++$games_for{$game{name}};
    ++$clan_games{$clan_of{$game{name}}} if exists $clan_of{$game{name}};

    if ($game{ascended})
    {
      ++$clan_ascs{$clan_of{$game{name}}} if exists $clan_of{$game{name}};
      ++$ascensions_for{$game{name}}[0];
      $ascensions_for{$game{name}}[1] = $num;

      # calculate asc streaks here because who needs another pass over all games
      my $a = ++$ascstreak_for{$game{name}}[0];
      $ascstreak_for{$game{name}}[1] = $num;
      if (!exists($best_ascstreak_for{$game{name}}) || $a > $best_ascstreak_for{$game{name}}[0])
      {
        $best_ascstreak_for{$game{name}} = [$a, $num];
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
}

sub demunge_realtime
{
  my $seconds = shift;
  my $hours = int($seconds / 3600);
  $seconds %= 3600;
  my $minutes = int($seconds / 60);
  $seconds %= 60;
  return sprintf "%d:%02d:%02d", $hours, $minutes, $seconds;
}

sub demunge_conduct
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
}

sub display_trophy
{
  my %player_info;

  # read arguments; tread lightly if you change this code
  my $args = shift;

  my $display_name = $args->{name};

  my $reverse     = defined($args->{need_reverse}) ? $args->{need_reverse}  : 0;
  my $list        = defined($args->{list})         ? $args->{list} : \@ascensions;
  $list = $args->{list_sub}() if defined($args->{list_sub});

  my $trophy_stat = $args->{trophy_stat}   || "";
  my $get_name    = $args->{get_name}      || sub {$_[0]{name}};
  my $grep        = $args->{grep_callback} || undef;
  my $sorter      = $args->{sorter}        || undef;

  if ($trophy_stat ne "" && !exists($all_fields{$trophy_stat}))
  {
    warn "I want to award the '$display_name' trophy based on the '$trophy_stat' field, but I've never heard of it. Aborting this trophy.\n";
    return;
  }

  my $display_callback = $args->{display_callback} ||
  sub
  {
    my $g = shift;
    sprintf "{{%s}} - %s", $g->{name}, $g->{$trophy_stat};
  };

  # how are we sorting? we need to maintain stability, so simple "reverse sort"
  # won't work
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
  }

  # actually do the sorting, after we narrow down the list we want
  my @sorted = @{$list};
  @sorted = $grep->(@sorted) if defined $grep;
  @sorted = sort $sorter @sorted;

  # go from index-by-gamenum to index-by-playername
  foreach my $n (0..$#sorted)
  {
    my $name = $get_name->($sorted[$n]);
    push @{$player_info{$name}}, {num => $n, rank => $n};
  }

  # build up output for each player
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
    pop @nums while $nums[-1] >= @sorted;

    # add trophy name to output, with a placeholder for clan points
    $txt_output_for{$name} .= $display_name . "<<TROPHY_CLAN_POINTS>>:\n";
    $html_output_for{$name} .= "    <hr />\n    <h3>$display_name<<TROPHY_CLAN_POINTS>></h3>\n";

    if (exists $txt_status{$display_name}{$name})
    {
      $txt_output_for{$name} .= $txt_status{$display_name}{$name};
      $txt_output_for{$name} .= "  Winners\n";
      $indent = '  ';
    }
    if (exists $html_status{$display_name}{$name})
    {
      $html_output_for{$name} .= $html_status{$display_name}{$name};
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
          $callback_html =~ s!{{.*}}!<a href="$scorer.html">$scorer</a>!g;
        }

        $txt_output_for{$name} .= sprintf "%s%s %d: %s\n", $indent, $my_score ? "*" : " ", $n+1, $callback_txt;
        $html_output_for{$name} .= sprintf "      <li%s>%s</li>\n", $my_score ? " class=\"me\"" : "", $callback_html;
      }
    }

    $html_output_for{$name} .= "    </ol>\n";
    if (!exists($player_info{$name}))
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
           sprintf ' (%d point%s)',
                   $clan_points,
                   $clan_points == 1 ? '' : 's';
         }
         else
         {
           ''
         }
       }eg;
    }
  }
}

sub write_pages
{
  my $directory = 'pages';
  my $extension = 'txt';
  my $post      = '';

  while (1)
  {
    my ($name, $output);

    # order is (player-txt, player-html, clan-txt, clan-html)
    if ($extension eq 'txt')
    {
      my $next_set = 0;
      if ($directory eq 'pages')
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
        $post = "  </body>\n</html>\n";
      }
    }

    if ($extension eq 'html')
    {
      my $next_set = 0;
      if ($directory eq 'pages')
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
                      " (0 points)"
                    }
                  }
                  else
                  {
                    ""
                  }
                }eg;

    open(my $handle, ">", "$directory/$name.$extension") or warn "Unable to open $directory/$name.$extension: $!";
    print {$handle} $output, $post;
    close $handle;
  }
}

sub b13_for
{
  my $games_ref = shift;
  my $best = 0;
  my $best_end = 0;
  my $last = 0;
  my $last_start = 0;
  my $name = $games_ref->[0]{name};

  foreach my $start (0..$#{$games_ref})
  {
    my $cur = 0;
    my $end = 0;
    my %seen = ();
    for (my $num = $start; $num < $start + 13 && $num < @{$games_ref}; ++$num)
    {
      my $game_ref = $games_ref->[$num];
      last unless defined $game_ref;
      next unless $game_ref->{ascended};
      last if $seen{$game_ref->{crga0}}++;
      ++$cur;
      $end = $game_ref->{num};
    }
    ($best, $best_end) = ($cur, $end) if $cur > $best;
    ($last, $last_start) = ($cur, $start) if $cur > $last;
  }

  my $cur_start = @{$games_ref} - 13;
  $cur_start = 0 if $cur_start < 0;

  my @type = ([$last_start, "Best"], [$cur_start, "Current"]);
 
  foreach (@type)
  {
    $html_status{"Best of 13"}{$name} .= "      <h4>$_->[1]</h4>\n";
    $html_status{"Best of 13"}{$name} .= "      <ol>\n";
    $txt_status{"Best of 13"}{$name} .= "  $_->[1]\n";

    my %seen;
    for my $num ($_->[0]..$_->[0]+12)
    {
      my $game_ref = $games_ref->[$num];
      last unless defined $game_ref;
      if (!$game_ref->{ascended})
      {
        $html_status{"Best of 13"}{$name} .= "        <li class=\"b13 death\">died</li>\n";
        $txt_status{"Best of 13"}{$name} .= sprintf "    %d. %s\n", 1+$num-$_->[0], "died";
        next;
      }
      if ($seen{$game_ref->{crga0}}++)
      {
        $html_status{"Best of 13"}{$name} .= "        <li class=\"b13 repeat\">$game_ref->{crga0} (repeated)</li>\n";
        $txt_status{"Best of 13"}{$name} .= sprintf "    %d. %s (repeated)\n", 1+$num-$_->[0], $game_ref->{crga0};
        last;
      }
      $html_status{"Best of 13"}{$name} .= "        <li class=\"b13 ascend\">$game_ref->{crga0}</li>\n";
      $txt_status{"Best of 13"}{$name} .= sprintf "    %d. %s\n", 1+$num-$_->[0], $game_ref->{crga0};
    }

    $html_status{"Best of 13"}{$name} .= "      </ol>\n";
    $txt_status{"Best of 13"}{$name} .= "\n";
  }
  return ($best, $best_end);
}

sub best_of_13
{
  my %games_for;

  # we want all the games of only people who've ascended
  foreach (@games)
  {
    push @{$games_for{$_->{name}}}, $_ if exists($ascensions_for{$_->{name}});
  }

  my @best_of_13;
  foreach my $player (keys %ascensions_for)
  {
    push @best_of_13, [$player, b13_for($games_for{$player})];
  }

  return \@best_of_13;
}

# entry point

print "Reading clan_info\n";
read_clan_info("clan_info");
print "Reading xlogfile\n";
read_xlogfile("xlogfile");

# read_xlogfile populates %txt_output_for's keys with each player
# so we put any initial text for each player's page here
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

  $txt_output_for{$name}  = sprintf "Player: %s\nAscensions: %d/%d (%.2f%%)\n%s\n", $name, $asc, $games_for{$name}, 100*$asc/$games_for{$name}, $clan_info;

  # html output
  $clan_info = exists $clan_of{$name} ? "<h2>Clan: $clan_of{$name}<<CLAN_POINTS:$name>></h2>\n"
                                      : "<h2>Clan: <em>none!</em></h2>\n";
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
    %s
    <ul id="mainlinks">
      <li><a href="%s.txt">plaintext version</a></li>
      <li><a href="../index.html">main page</a></li>
      <li><a href="../winners.html">trophy winners</a></li>
      <li><a href="http://alt.org/nethack/">nethack.alt.org</a></li>
    </ul>
EOH

  $html_output_for{$name} = sprintf $format_string, $name, $name, $asc, $games_for{$name}, 100*$asc/$games_for{$name}, $clan_info, $name;

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
}

# read_clan_info populates %clan_txt_output_for's keys with each clan
# so we put any initial text for each clan's page here
foreach my $clan (keys %clan_txt_output_for)
{
  my $roster = join '',
               map { "  $_<<CLAN_POINTS:$_>>\n" }
               sort
               keys %{$clan_roster{$clan}};
  $clan_txt_output_for{$clan} = sprintf "Clan: %s\nAscensions: %d/%d (%.2f%%)\n\nRoster:\n%s\n", $clan, $clan_ascs{$clan} || 0, $clan_games{$clan} || 0, $clan_games{$clan} ? 100*$clan_ascs{$clan}/$clan_games{$clan} : 0, $roster;
}

# prefer data structures to code
my @trophies =
(
  {
    name             => "Best of 13",
    clan_points      => 10,
    list_sub         => \&best_of_13,
    sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
    get_name         => sub { $_[0][0] },
    display_callback => sub {my $b13 = shift; sprintf "{{%s}} - %d", $b13->[0], $b13->[1]}
  },
  {
    name             => "Most ascensions",
    clan_points      => 9,
    list_sub         => sub {[map {[$_, @{$ascensions_for{$_}}]} keys %ascensions_for]},
    sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
    get_name         => sub { $_[0][0] },
    display_callback => sub {my $ma = shift; sprintf "{{%s}} - %d", $ma->[0], $ma->[1]}
  },
  {
    name             => "Longest ascension streak",
    clan_points      => 9,
    list_sub         => sub {[map {[$_, @{$best_ascstreak_for{$_}}]} keys %best_ascstreak_for]},
    sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
    get_name         => sub { $_[0][0] },
    display_callback => sub {my $ma = shift; sprintf "{{%s}} - %d", $ma->[0], $ma->[1]}
  },
  {
    name             => "First ascension",
    clan_points      => 6,
    trophy_stat      => "endtime",
    display_callback => sub {my $g = shift; my $time = gmtime($g->{endtime} - 8 * 3600); $time =~ s/  / /; sprintf "{{%s}} - #%d (%s)", $g->{name}, $g->{num}, $time}
  },
  {
    name             => "Fastest ascension",
    clan_points      => 8,
    trophy_stat      => "turns",
    display_callback => sub {my $g = shift; sprintf "{{%s}} - T:%d", $g->{name}, $g->{turns}}
  },
  {
    name             => "Quickest ascension",
    clan_points      => 8,
    trophy_stat      => "realtime",
    display_callback => sub {my $g = shift; sprintf "{{%s}} - %s", $g->{name}, demunge_realtime($g->{realtime})}
  },
  {
    name             => "Best behaved ascension",
    clan_points      => 7,
    trophy_stat      => "conducts",
    need_reverse     => 1,
    display_callback => sub {my $g = shift; sprintf "{{%s}} - %d: %s", $g->{name}, $g->{conducts}, (join ', ', demunge_conduct($g->{conduct})) || "(none)"}
  },
  {
    name             => "Extinctionist",
    clan_points      => 5,
    trophy_stat      => "kills",
    list             => \@games,
    display_callback => sub {my $g = shift; sprintf "{{%s}} - %d kill%s", $g->{name}, $g->{kills}, $g->{kills} == 1 ? "" : "s"}
  },
  {
    name             => "Truest pacifist ascension",
    clan_points      => 5,
    trophy_stat      => "kills",
    needs_reverse    => 1,
    display_callback => sub {my $g = shift; sprintf "{{%s}} - %d kill%s", $g->{name}, $g->{kills}, $g->{kills} == 1 ? "" : "s"}
  },
  {
    name             => "Low-scoring ascension",
    clan_points      => 7,
    trophy_stat      => "points",
    display_callback => sub {my $g = shift; sprintf "{{%s}} - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
  },
  {
    name             => "High-scoring ascension",
    clan_points      => 5,
    trophy_stat      => "points",
    need_reverse     => 1,
    display_callback => sub {my $g = shift; sprintf "{{%s}} - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
  }
);

foreach my $role (@roles)
{
  push @trophies,
  {
    name             => "High-scoring $expand{$role}",
    clan_points      => 2,
    list             => \@games,
    trophy_stat      => "points",
    need_reverse     => 1,
    grep_callback    => sub {grep {$_->{role} eq $role} @_},
    display_callback => sub {my $g = shift; $|++; sprintf "{{%s}} - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
  };
}

foreach my $trophy_ref (@trophies)
{
  print "Processing $trophy_ref->{name}\n";
  display_trophy($trophy_ref);
}

print "Printing player and clan pages\n";
write_pages();
