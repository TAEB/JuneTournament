#!/usr/bin/perl
use strict;
use warnings;

my %game;

my %compress = # {{{
(
  Archeologist => 'Arc',
  Barbarian    => 'Bar',
  Caveman      => 'Cav',
  Cavewoman    => 'Cav',
  Healer       => 'Hea',
  Knight       => 'Kni',
  Monk         => 'Mon',
  Priest       => 'Pri',
  Priestess    => 'Pri',
  Ranger       => 'Ran',
  Rogue        => 'Rog',
  Samurai      => 'Sam',
  Tourist      => 'Tou',
  Valkyrie     => 'Val',
  Wizard       => 'Wiz',

  Dwarf        => 'Dwa',
  Elf          => 'Elf',
  Gnome        => 'Gno',
  Human        => 'Hum',
  Orc          => 'Orc',

  Dwarven      => 'Dwa',
  Elven        => 'Elf',
  Gnomish      => 'Gno',
  Orcish       => 'Orc',

  Lawful       => 'Law',
  Neutral      => 'Neu',
  Chaotic      => 'Cha',

  Male         => 'Mal',
  Female       => 'Fem',
);

foreach my $key (keys %compress)
{
  next unless $key =~ y/A-Z//;
  $compress{lc $key} = $compress{$key};
} # }}}

sub try_set # {{{
{
  my ($field, $value, $whence) = @_;
  if (exists $game{$field} && $game{$field} ne $value)
  {
    die "Trying to re-set \$game{$field} (= $game{$field}) to $value from $whence.";
  }
  $game{$field} = $value;
} # }}}

sub munge_conducts # {{{
{
  my $result = 0;

  my %hex_for =
  (
    foodless     => 0x0001,
    vegan        => 0x0002,
    vegetarian   => 0x0004,
    atheist      => 0x0008,
    weaponless   => 0x0010,
    pacifist     => 0x0020,
    illiterate   => 0x0040,
    polyitemless => 0x0080,
    polyselfless => 0x0100,
    wishless     => 0x0200,
    artiwishless => 0x0400,
    genoless     => 0x0800,
  );

  foreach (@_)
  {
    $result |= $hex_for{$_};
  }

  return $result;
} # }}}

my $in_vanquished = 0;
my $my_kill_count = 0;
my @conducts;

LINE: while (<>) # {{{
{
  chomp;
  if ($in_vanquished)
  {
    if (/^  (\d+) creatures? vanquished\.$/)
    {
      $in_vanquished = 0;
      try_set('kills', $1, 'nethack\'s kill count');
      next LINE;
    }

    if (/^  (.*)/)
    {
      if ($1 =~ /^(\d+)/)
      {
        $my_kill_count += $1;
      }
      else
      {
        ++$my_kill_count;
      }
      next LINE;
    }

    try_set('kills', $my_kill_count, 'my kill count');
    $in_vanquished = 0;
  }
  elsif (/^Vanquished creatures$/)
  {
    $in_vanquished = 1;
  }

  if ($. == 1)
  {
    /^(\w+), (\w+) (\w+) (\w+) (\w+)$/
      or die "Unable to handle the first line of input, expected 'name, align gender race role' got $_";

    for ([name   => $1],
         [align  => $compress{$2}],
         [gender => $compress{$3}],
         [race   => $compress{$4}],
         [role   => $compress{$5}])
    {
      try_set($_->[0], $_->[1], 'first line');
    }

    next LINE;
  }

  if (/^(?:$game{name} the [\w\s]+)?\s*St:(\d+|18\/\d\d|18\/\*\*) Dx:(\d+) Co:(\d+) In:(\d+) Wi:(\d+) Ch:(\d+).*(Lawful|Neutral|Chaotic)/)
  {
    for ([str   => $1],
         [dex   => $2],
         [con   => $3],
         [int   => $4],
         [wis   => $5],
         [cha   => $6],
         [align => $compress{$7}])
    {
      try_set($_->[0], $_->[1], 'botl');
    }

    next LINE;
  }

  if (/^Killer: (.+)$/)
  {
    try_set("death",    $1,                       'Killer line');
    next LINE;
  }

  if (/^You were level (\d+) with a maximum of (\d+) hit points? when you/)
  {
    for ([xl    => $1],
         [maxhp => $2])
    {
      try_set($_->[0], $_->[1], 'You were level ...');
    }

    next LINE;
  }

  if (/^and (\d+) pieces? of gold, after ([\d-]+) moves?\.$/)
  {
    for ([gold  => $1],
         [turns => $2])
    {
      try_set($_->[0], $_->[1], 'and x gold, after y moves');
    }

    next LINE;
  }

  if (/^(?:You )?went to your reward with (-?\d+) points?,$/)
  {
    try_set("ascended", 1, 'Killer line');
    try_set("score", $1, 'You went to your reward with x points');
    next LINE;
  }

  push @conducts, "illiterate" if /^\s*You were illiterate\s*$/;
  push @conducts, "genoless" if /^\s*You never genocided any monsters\s*$/;
  push @conducts, "weaponless" if /^\s*You never hit with a wielded weapon\s*$/;
  push @conducts, "pacifist" if /^\s*You were a pacifist\s*$/;
  push @conducts, "atheist" if /^\s*You were an atheist\s*$/;
  push @conducts, "polyitemless" if /^\s*You never polymorphed an object\s*$/;
  push @conducts, "polyselfless" if /^\s*You never changed form\s*$/;
  push @conducts, "wishless", "artiwishless" if /^\s*You used no wishes\s*$/;
  push @conducts, "artiwishless" if /^\s*You did not wish for any artifacts\s*$/;
  push @conducts, "foodless", "vegan", "vegetarian" if /^\s*You went without food\s*$/;
  push @conducts, "vegan", "vegetarian" if /^\s*You followed a strict vegan diet\s*$/;
  push @conducts, "vegetarian" if /^\s*You were a vegetarian\s*$/;
} # }}}

$game{conduct} = munge_conducts(@conducts);
$game{conducts} = scalar @conducts;

print join ':', map {y/:/_/; $_}
                map {"$_=$game{$_}"}
                keys %game;
print "\n";

