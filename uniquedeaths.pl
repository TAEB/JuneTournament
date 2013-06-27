#!/usr/bin/perl
use warnings;
use strict;

# This script takes a logfile on stdin and prints the deaths to stdout.
# Complain to Eidolos about bugs.

# http://alt.org/nethack/player-all-raw.php?player=DeathRobin

my @regex;
my @regex_friendly;
my @count;
my $line;
my $matched;
my $i;
my %i;
my $unique = 0;
my $deaths = 0;
my $unmatched = 0;
my $manymatched = 0;
my @unmatched;

# Read in the regexen from the bottom of this file.
while ($line = <DATA>)
{
  chomp $line;
  push @regex, qr/^$line$/;
  push @regex_friendly, $line;
  push @count, 0;
}

while ($line = <>)
{
  $matched = 0;
  ++$deaths;
  if ($line =~ /^\d\.\d\.\d /)
  {
    $line =~ s/^[^,]+,//; #extract just the death
  }
  
  for ($i = 0; $i < @regex; ++$i)
  {
    if ($line =~ $regex[$i])
    {
      ++$matched;
      ++$unique unless $count[$i]++;
    }
  }
  if ($matched == 0)
  {
    $unmatched++;
    push @unmatched, $line;
  }
  elsif ($matched > 1)
  {
    $manymatched++;
  }
}

for ($i = 0; $i < @count; ++$i)
{
  $i{$i} = $count[$i];
}

printf "Unique deaths accomplished: %d/%d (%.2f%%)\n", $unique, $#regex, 100*$unique/$#regex;
printf "Repeat deaths:              %d/%d (%.2f%%)\n", $deaths-$unique, $deaths, 100*($deaths-$unique)/$deaths;
printf "Deaths that match no regex: %d/%d (%.2f%%)\n", $unmatched, $deaths, 100*$unmatched/$deaths;
printf "Deaths that match >1 regex: %d/%d (%.2f%%)\n", $manymatched, $deaths, 100*$manymatched/$deaths;
printf "Last calculated:            %s UTC\n\n", scalar gmtime;

printf "UNACHIEVED\n";
printf "----------\n";

printf "%s\n", $regex_friendly[$_]
  for (sort {$regex_friendly[$a] cmp $regex_friendly[$b]} grep {!$i{$_}} keys %i);

printf "\nACHIEVED\n";
printf "--------\n";

printf "  %-3d %s\n", $count[$_], $regex_friendly[$_] 
  for (sort {$i{$b} <=> $i{$a} || $regex_friendly[$a] cmp $regex_friendly[$b]} grep {$i{$_}} keys %i);

printf "\nUNMATCHED\n";
printf "---------\n";
print for @unmatched;

# These regexen provided by the devnull tournament guys.
__END__
.*\(with the Amulet\)
.* with a fake Amulet
ascended
quit
escaped
escaped \(in celestial disgrace\)
panic
(died of )?starvation
a trickery
(killed by )?a scroll of genocide
committed suicide
went to heaven prematurely
teleported out of the dungeon and fell to (his|her) death
unwisely tried to eat (Death|Famine|Pestilence)
unwisely ate the body of (Death|Famine|Pestilence)
slipped while mounting a saddled .*
fell into a pit
fell into a pit of iron spikes
fell into a chasm
fell onto a sink
zapped (him|her)self with a wand
zapped (him|her)self with a spell
shot (him|her)self with a death ray
caught (him|her)self in (his|her) own magical blast
caught (him|her)self in (his|her) own death field
caught (him|her)self in (his|her) own (fireball|ball of lightning|ball of cold)
caught (him|her)self in (his|her) own burning oil
choked on a (food ration|cram ration|lembas wafer)
choked on (a pancake|a candy bar|a fortune cookie|an egg|a cream pie)
choked on (a slime mold|a melon|an orange|a papaya|a banana|an apple|a carrot)
choked on (a sprig of wolfsbane|a lump of royal jelly)
choked on a tripe ration
choked on a tin of spinach
choked on a tin of .* meat
choked on a candied tin of .* meat
choked on a tin of .*
choked on a.* corpse
choked on a.* huge chunk of meat
poisoned by (Demogorgon|Juiblex|Scorpius)
poisoned by Pestilence
poisoned by a poisoned blast
poisoned by a rotted .* corpse
poisoned by a rotten lump of royal jelly
poisoned by a unicorn horn
poisoned by a.* (dart|arrow|crossbow bolt)
poisoned by a fall onto poison spikes
poisoned by a vampire bat
poisoned by a.* (ant|water moccasin|centipede|bee|snake|scorpion|spider|quasit)
poisoned by a.* rabid .*
petrified by elementary physics
petrified by Medusa
petrified by tasting Medusa meat
petrified by deliberately (gazing at Medusa's hideous countenance|meeting Medusa's gaze)
petrified by tasting (cockatrice|chickatrice) meat
petrified by swallowing a cockatrice whole
petrified by a cockatrice egg
petrified by a (cockatrice|chickatrice) corpse
petrified by stolen cockatrice corpse
petrified by trying to tin a cockatrice without gloves
petrified by trying to help a cockatrice out of a pit
petrified by attempting to saddle a (cockatrice|chickatrice)
petrified by kicking a (cockatrice|chickatrice) corpse without boots
petrified by a (cockatrice|chickatrice|rock troll)
petrified by a.* (soldier|captain)
turned into green slime
turned to slime by a green slime
turned to slime by a cockatrice egg
drowned in a (pool of water|moat)
drowned in a (pool of water|moat) by a.*
(burned by molten lava|dissolved in molten lava)
crushed to death by a collapsing drawbridge
crushed to death by an exploding drawbridge
crushed to death by a falling drawbridge
crushed to death by a closing drawbridge
squished under a boulder
crunched in the head by an iron ball
dragged downstairs by an iron ball
using a magical horn on (him|her)self
killed while stuck in creature form
killed (him|her)self with (his|her) bullwhip
killed (him|her)self by breaking a wand
killed by a server failure
killed by.* were.*
killed by.* invisible .*
killed by.* hallucinogen-distorted .*
killed by.*, (while helpless|while help)
killed by elementary chemistry
killed by an imperious order
killed by (his|her) own (pick-axe|dwarvish mattock|axe|battle-axe)
killed by (contaminated water|contaminated tap water)
killed by boiling water
killed by a cadaver
killed by petrification
killed by strangulation
killed by brainlessness
killed by overexertion
killed by exhaustion
killed by genocidal confusion
killed by self-genocide
killed by life drainage
killed by an exploding rune
killed by an unsuccessful polymorph
killed by dangerous winds
killed by kicking .* (boulder|statue of a.*|rock|rocks|flint stone|touchstone|gray stone|gem)
killed by kicking .* (wall|door|sink|fountain|headstone|stairs|altar|electric chair)
killed by kicking a heavy iron ball \(chained to you\)
killed by kicking a.* corpse
killed by kicking .* (ring|spellbook|scroll|key|whistle|blindfold|leash|stethoscope|lamp|cloth|mail|helm|helmet|shield|armor|shirt|cloak|axe|scalpel|chain|sword|dagger|darts|fortune cookie|garlic|spinach|slime mold|apples|carrots|food ration|gold pieces|\(.*\))
killed by axing a hard object
killed by leg damage from being pulled out of a bear trap
killed by a riding accident
killed by sipping boiling water
killed by touching (The Staff of Aesculapius|The Orb of Fate|The Mitre of Holiness|The Master Key of Thievery|The Orb of Detection)
killed by touching (Excalibur|Grayswandir|Sting|Sunsword|Magicbane|Stormbringer|Cleaver)
killed by bumping into a (door|wall|boulder)
killed by falling downstairs
killed by a fall onto poison spikes
killed by sitting on lava
killed by sitting on an iron spike
killed by jumping out of a bear trap
killed by colliding with the ceiling
killed by a residual undead turning effect
killed by an electric shock
killed by a system shock
killed by an explosion
killed by a magical explosion
killed by an iron ball collision
killed by a death ray
killed by a magic missile
killed by a touch of death
(killed by a tower of flame|tower of flame)
killed by a psychic blast
killed by an alchemic blast
killed by a blast of (fire|frost|missiles|disintegration|acid)
killed by a bolt of (fire|cold|lightning)
killed by a (gas cloud|cloud of poison gas)
killed by a wand
killed by an exploding wand
killed by an exploding ring
killed by a scroll of earth
killed by a scroll of fire
killed by a burning scroll
killed by a burning book
killed by a contact-poisoned spellbook
killed by a potion of acid
killed by a potion of (holy|unholy) water
killed by a thrown potion
killed by (a shattered potion|shattered potions)
killed by (a boiling potion|boiling potions)
killed by (a|a mildly) contaminated potion
killed by a burning potion of oil
killed by a carnivorous bag
killed by an exploding (large box|chest)
killed by an exploding crystal ball
killed by a grappling hook
killed by a.* (dagger|spear|dart|javelin|halberd|spetum|shuriken|boomerang|knife|bill-guisarme)
killed by a.* (crossbow bolt|arrow|ya)
killed by a.* piece of .* glass
killed by (Mjollnir|a war hammer named Mjollnir)
killed by a falling (object|rock)
killed by a boulder
killed by a land mine
killed by a cursed throne
killed by an electric chair
killed by a poisonous corpse
killed by an acidic corpse
killed by the ghost of .*
killed by the wrath of .*
killed by a priest.* of .*
killed by (a couatl|an Angel) of .*
killed by.* Izchak(, the shopkeeper)?
killed by (.* the shopkeeper|.*(Mr.|Ms.) .*)
killed by .*(Master Kaen|Ashikaga Takauji|the Cyclops|Lord Surtur|the Minion of Huhetotl)
killed by (the Oracle|Croesus)
killed by .*(Yeenoghu|Asmodeus|Juiblex|Demogorgon|Scorpius)
killed by .*(Death|War|Famine|Pestilence)
killed by a.* tourist
killed by a.* (wumpus|grid bug|light|nurse|Keystone Kop|Kop Sergeant|Kop Lieutenant|Kop Kaptain)
(killed by a.* (soldier|guard|sergeant|lieutenant|captain|watchman|watch captain)|lieutenant)
killed by a.* (woodchuck|newt)
killed by a.* (titanothere|baluchitherium|mastodon)
killed by a.* (rat|mole|bat|kitten|housecat|cat|jaguar|lynx|panther|tiger|dog|dingo|wolf|jackal|coyote|fox|pony|horse|ape|warhorse|monkey)
killed by a.* (crocodile|water moccasin|snake|pit viper|iguana|chameleon|gecko|lizard|cobra)
killed by a.* (raven)
killed by a.* (salamander)
killed by a.* (shark|eel)
killed by a.* (ant|beetle|bee|centipede)
killed by a.* (spider|scorpion)
killed by a.* (blob|gas spore|.* sphere|jelly|fog cloud|vortex|pudding|ooze|mold|fungus|green slime)
killed by a.* (homunculus|yeti|sasquatch|hell hound|chickatrice|cockatrice|pyrolisk|golem|gnome|gnomish wizard|ogre king|ogre lord|ogre|elemental|ettin)
killed by a.* (tengu|gremlin|gargoyle|goblin|hobgoblin|unicorn|centaur|dragon|leprechaun|nymph|giant|troll|minotaur|xan)
killed by a.* (hobbit|dwarf|.*\-[eE]lf|elf-lord|Elvenking|orc|Uruk\-hai|Olog-hai|warg|jabberwock|balrog|mumak|kraken)
killed by a.* (mummy|zombie|vampire|wraith|barrow wight|ghoul|lich|demilich|arch-lich|shade)
killed by a.* (floating eye|shrieker|worm|mimic|piercer|lurker above|trapper|bugbear|mind flayer|kobold|owlbear|xorn|gelatinous cube|umber hulk)
killed by a.* (couatl|Angel|Aleax|Archon|ki-rin|naga|titan)
killed by a.* (manes|imp|succubus|incubus|.* demon|.* devil|djinni|vrock|hezrou|quasit|marilith|pit fiend|nalfeshnee)
killed by a.* (rothe|leocrotta|zruty|disenchanter)
killed by a.* called .*
