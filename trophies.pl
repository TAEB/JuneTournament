#!/usr/bin/perl
use strict;
use warnings;

my @games;
my @ascensions;
my %games_for;
my %ascensions_for;
my %best_ascstreak_for;
my %output_for;

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

    foreach (split /:/, $_)
    {
      next unless /^([^=]+)=(.*)$/;
      $game{$1} = $2;
    }

    next if $game{death} eq "a trickery";

    $game{ascended} = $game{death} eq 'ascended' ? 1 : 0;
    $game{conducts} = scalar demunge_conduct($game{conduct});
    $game{num}      = $num;

    ++$games_for{$game{name}};

    if ($game{ascended})
    {
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

    $output_for{$game{name}} = "";
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

  # read arguments, lot of subtleties here!
  my $args = shift;

  my $display_name = $args->{name};

  my $reverse     = defined($args->{need_reverse}) ? $args->{need_reverse}  : 0;
  my $sort        = defined($args->{need_sort})    ? $args->{need_sort}     : 1;
  my $list        = defined($args->{list})         ? $args->{list} : \@ascensions;
  $list = $args->{list_sub}() if defined($args->{list_sub});

  my $trophy_stat = $args->{trophy_stat}   || "foo";
  my $get_name    = $args->{get_name}      || sub {$_[0]{name}};
  my $grep        = $args->{grep_callback} || undef;
  my $sorter      = $args->{sorter}        || undef;

  my $display_callback = $args->{display_callback} ||
  sub 
  {
    my $g = shift; 
    sprintf "%s %s", $g->{name}, $g->{$trophy_stat}
  };

  # how are we sorting? we need to maintain stability, so reverse sort is bad
  if ($sort && !defined($sorter))
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

  # get the list we want in the correct order
  my @sorted = @{$list};
  @sorted = $grep->(@sorted) if defined $grep;
  @sorted = sort $sorter @sorted if $sort;

  # go from index-by-gamenum to index-by-playername
  foreach my $n (0..$#sorted)
  {
    my $name = $get_name->($sorted[$n]);
    push @{$player_info{$name}}, {num => $n, rank => $n};
  }

  # build up output for each player
  foreach my $name (keys %output_for)
  {
    my $num;
    my @nums = (0..2);

    # does this player have any games eligible for this trophy?
    # if not we just display the top three
    if (exists($player_info{$name}))
    {
      $num = $player_info{$name}[0]{num};

      # display top 3 and 2 around, or top N if sufficiently highly ranked
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

    # add trophy name to output
    $output_for{$name} .= $display_name . ":\n";

    foreach my $n (@nums)
    {
      if (ref($n))
      {
        $output_for{$name} .= "  ...\n";
      }
      else
      {
        my $pre = defined($num) && $n == $num ? "*" : " ";
        $output_for{$name} .= sprintf "%s %d: %s\n", $pre, $n+1, $display_callback->($sorted[$n]);
      }
    }
    if (!exists($player_info{$name}))
    {
      $output_for{$name} .= "  (No eligible games for $name)\n";
    }
    $output_for{$name} .= "\n";
  }
}

sub write_pages
{
  while (my ($name, $output) = each %output_for)
  {
    open(my $handle, ">", "pages/$name.txt") or warn "Unable to open $name.html: $!";
    print {$handle} $output;
    close $handle;
  }
}

sub b13_for
{
  my $games_ref = shift;
  my $best = 0;
  my $best_end = 0;

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
      last if $seen{join ' ', ($game_ref->{role}, $game_ref->{race}, $game_ref->{gender0}, $game_ref->{align0})}++;
      ++$cur;
      $end = $game_ref->{num};
    }
    ($best, $best_end) = ($cur, $end) if $cur > $best;
  }

  return ($best, $best_end);
}

sub best_of_13
{
  my %games_for;
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

# and now the actual code

read_xlogfile("xlogfile");
foreach my $name (keys %output_for)
{
  my $asc = exists($ascensions_for{$name}) ? $ascensions_for{$name}[0] : 0;
  $output_for{$name} = sprintf "Player: %s\nAscensions: %d/%d (%.2f%%)\n\n", $name, $asc, $games_for{$name}, 100*$asc/$games_for{$name};
}

my @trophies =
(
  {
    name             => "Best of 13",
    list_sub         => \&best_of_13,
    sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
    get_name         => sub { $_[0][0] },
    display_callback => sub {my $b13 = shift; sprintf "%s %d", $b13->[0], $b13->[1]}
  },
  {
    name             => "Most ascensions",
    list_sub         => sub {[map {[$_, @{$ascensions_for{$_}}]} keys %ascensions_for]},
    sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
    get_name         => sub { $_[0][0] },
    display_callback => sub {my $ma = shift; sprintf "%s %d", $ma->[0], $ma->[1]}
  },
  {
    name             => "Longest ascension streak",
    list_sub         => sub {[map {[$_, @{$best_ascstreak_for{$_}}]} keys %best_ascstreak_for]},
    sorter           => sub { $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]},
    get_name         => sub { $_[0][0] },
    display_callback => sub {my $ma = shift; sprintf "%s %d", $ma->[0], $ma->[1]}
  },
  {
    name             => "First ascension",
    trophy_stat      => "num",
    need_sort        => 0,
    display_callback => sub {my $g = shift; my $time = gmtime($g->{endtime} - 8 * 3600); $time =~ s/  / /; sprintf "%s #%d (%s)", $g->{name}, $g->{num}, $time}
  },
  {
    name             => "Fastest ascension",
    trophy_stat      => "turns",
    display_callback => sub {my $g = shift; sprintf "%s T:%d", $g->{name}, $g->{turns}}
  },
  {
    name             => "Quickest ascension",
    trophy_stat      => "realtime",
    display_callback => sub {my $g = shift; sprintf "%s %s", $g->{name}, demunge_realtime($g->{realtime})}
  },
  {
    name             => "Best behaved ascension",
    trophy_stat      => "conducts",
    need_reverse     => 1,
    display_callback => sub {my $g = shift; sprintf "%s - %d: %s", $g->{name}, $g->{conducts}, (join ', ', demunge_conduct($g->{conduct})) || "(none)"}
  },
  {
    name             => "Low-scoring ascension",
    trophy_stat      => "points",
    display_callback => sub {my $g = shift; sprintf "%s - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
  },
  {
    name             => "High-scoring ascension",
    trophy_stat      => "points",
    need_reverse     => 1,
    display_callback => sub {my $g = shift; sprintf "%s - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
  }
);

foreach my $role (@roles)
{
  push @trophies,
  {
    name             => "High-scoring $expand{$role}",
    list             => \@games,
    trophy_stat      => "points",
    need_reverse     => 1,
    grep_callback    => sub {grep {$_->{role} eq $role} @_},
    display_callback => sub {my $g = shift; $|++; sprintf "%s - %d point%s", $g->{name}, $g->{points}, $g->{points} == 1 ? "" : "s"}
  };
}

foreach my $trophy_ref (@trophies)
{
  display_trophy($trophy_ref);
}

write_pages();
