#!/usr/bin/perl
use strict;
use warnings;

my %game;

my %compress =
(
  Archeologist => 'Arc',
  Barbarian    => 'Bar',
  Caveman      => 'Cav',
  Healer       => 'Hea',
  Knight       => 'Kni',
  Monk         => 'Mon',
  Priest       => 'Pri',
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
}

sub try_set
{
  my ($field, $value, $whence) = @_;
  if (exists $game{$field} && $game{$field} ne $value)
  {
    die "Trying to re-set \$game{$field} (= $game{$field}) to $value from $whence.";
  }
  $game{$field} = $value;
}

my $in_vanquished = 0;
my $my_kill_count = 0;

LINE: while (<>)
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

    for ([name  => $1],
         [align => $compress{$2}],
         [race  => $compress{$3}],
         [role  => $compress{$4}])
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
  }

  if (/^Killer: (.+)$/)
  {
    try_set("ascended", $1 eq 'ascended' ? 1 : 0, 'Killer line');
    try_set("death",    $1,                       'Killer line');
  }

  if (/^You were level (\d+) with a maximum of (\d+) hit points? when you/)
  {
    for ([xl    => $1],
         [maxhp => $2])
    {
      try_set($_->[0], $_->[1], 'You were level ...');
    }
  }

  if (/^and (\d+) pieces? of gold, after (\d+) moves?\.$/)
  {
    for ([gold  => $1],
         [turns => $2])
    {
      try_set($_->[0], $_->[1], 'and x gold, after y moves');
    }
  }

  if (/^You .+ with (\d+) points?,$/)
  {
    try_set("score", $1, 'You blehed with x points');
  }
}

print join ':', map {y/:/_/; $_}
                map {"$_=$game{$_}"}
                keys %game;
print "\n";

