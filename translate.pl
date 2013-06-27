#!/usr/bin/perl
while (<>)
{
  my @F = split /:/;
  my %game;
  %game = (%game, split /=/) foreach @F;
  
  print "$game{points} $game{deathlev} $game{maxlvl} $game{hp} $game{maxhp} $game{deaths} $game{turns} 0 0 $game{birthdate} $game{deathdate} $game{role} $game{race} $game{gender} $game{align} {} $game{name},$game{death}\n";
}

