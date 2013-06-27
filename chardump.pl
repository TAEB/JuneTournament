#!/usr/bin/perl

my %tln = (
            'lawful' => 'Law', 
            'neutral' => 'Neu', 
            'chaotic' => 'Cha', 
            
            'male' => 'Mal', 
            'female' => 'Fem', 
            
            'human', => 'Hum', 
            'orcish' => 'Orc', 
            'elven' => 'Elf', 
            'dwarven' => 'Dwa', 
            'gnomish' => 'Gno', 
            
            'Archeologist' => 'Arc', 
            'Barbarian' => 'Bar', 
            'Caveman' => 'Cav', 
            'Cavewoman' => 'Cav', 
            'Healer' => 'Hea', 
            'Knight' => 'Kni', 
            'Monk' => 'Mon', 
            'Priest' => 'Pri', 
            'Priestess' => 'Pri', 
            'Rogue' => 'Rog', 
            'Ranger' => 'Ran', 
            'Samurai' => 'Sam', 
            'Tourist' => 'Tou', 
            'Valkyrie' => 'Val', 
            'Wizard' => 'Wiz',
          );

my $vanquished;
my $turns;
my $gold;
my $ascended = 0;
my $score;
my $maxhp;

my $conducts = 0;
my @conducts;

# chardumps always start with a line like "Eidolos, neutral male human Wizard"
my $identifier = <>;
my ($name, $align, $gender, $race, $role) = $identifier =~ /^\s*([^,]+), (\w+) (\w+) (\w+) (\w+)\s*$/;
$align = $tln{$align};
$gender = $tln{$gender};
$race = $tln{$race};
$role = $tln{$role};

sub report
{
  my $field = shift;
  my $value = shift;
  if (defined $value)
  {
    print "$field: $value\n";
  }
  else
  {
    print "$field unavailable\n";
  }
}

while (<>)
{
  $vanquished = $1, next if /^\s*(\d+) creatures? vanquished\.\s*$/;
  ($gold, $turns) = ($1, $2), next if /^\s*and (\d+) pieces? of gold, after (\d+) moves?\.\s*$/;
  $score      = $1, next if /^\s*(?:You )?went to your reward with (\d+) points?,\s*$/;
  $maxhp      = $1, next if /^\s*You were level \d+ with a maximum of (\d+) hit points? when you ascended\.\s*$/;
  $ascended   = 1, next if /^\s*Killer: ascended\s*$/;
  $conducts   = 1, next if /^\s*Voluntary challenges\s*$/;

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
}

print "Name: $name\n";
print "Char: $role $race $gender $align\n";
print "Ascended? " . ($ascended ? "yes" : "no") . "\n";

report('Score', $score);
report('Vanquished', $vanquished);
report('Turns', $turns);
report('Gold', $gold);
report('Max HP', $maxhp);

if (!$conducts && !@conducts)
{
  print "Conducts unavailable\n";
}
else
{
  print "Conducts (" . ($#conducts+1) . "):";
  print " $_" foreach @conducts;
  print "\n";
}

