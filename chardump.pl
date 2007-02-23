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

LINE: while (<>)
{
  chomp;
  if ($. == 1)
  {
    @game{qw{name align gender race role}} =
      map {exists $compress{$_} ? $compress{$_} : $_}
      /^(\w+), (\w+) (\w+) (\w+) (\w+)$/
        or die "Unable to handle the first line of input, expected 'name, align gender race role' got $_";
    next LINE;
  }

  if (/^(?:$game{name} the [\w\s]+)?\s*St:(\d+|18\/\d\d|18\/\*\*) Dx:(\d+) Co:(\d+) In:(\d+) Wi:(\d+) Ch:(\d+)(.*)/)
  {
    @game{qw{str dex con int wis cha}} = ($1, $2, $3, $4, $5, $6);
    my $remaining = $7;
    if ($remaining =~ /\b(Lawful|Neutral|Chaotic)\b/)
    {
      try_set('align', $compress{$1}, 'botl');
    }
    if ($remaining =~ /\bS:(-?\d+)/)
    {
      try_set('score', $1, 'botl');
    }
  }

  if (m{
         ^
         (
           Astral Plane
         )
         \s+
         [\$*]:(\d+)           # shows up as *:130 on rogue level
         \s+
         HP:(-?\d+)\(-?\d+\)
         \s+
         Pw:(-?\d+)\(-?\d+\)
         \s+
         AC:(-?\d+)
         \s+
         (                    # affected by showexp
           Xp:\d+/\d+
           |
           Exp:\d+
         )
         \s*
         (?:
           T:(-?\d+)
         )?
         $
       }x)
  {
  }
#Astral Plane $:0  HP:311(437) Pw:22(109) AC:-37 Xp:16/436138 T:67546
}

print join ':', map {s/:/_/g; $_}
                map {"$_=$game{$_}"}
                keys %game;
print "\n";

