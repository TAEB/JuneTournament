###############################################################################
# Copyright (c) 2006 Shawn M Moore                                            #
#                                                                             #
# Permission is hereby granted, free of charge, to any person obtaining a     #
# copy of this software and associated documentation files (the "Software"),  #
# to deal in the Software without restriction, including without limitation   #
# the rights to use, copy, modify, merge, publish, distribute, sublicense,    #
# and/or sell copies of the Software, and to permit persons to whom the       #
# Software is furnished to do so, subject to the following conditions:        #
#                                                                             #
# The above copyright notice and this permission notice shall be included in  #
# all copies or substantial portions of the Software.                         #
#                                                                             #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         #
# DEALINGS IN THE SOFTWARE.                                                   #
###############################################################################

# Version: 1.2.1 [16:23 05 May 06]

# This module's purpose is to get the logfile from a file and put it into an
# array of hashes. That's all. The return value of parse_file is an array of 
# hashes sorted in the order that the games appear in the logfile. To see what
# goes into the hash, check near the end of this file.

# This module will work with or without the turns-in-logfile patch. If the
# turn count is undetected, a value of zero is used. I would've preferred to
# use '?' but I figure we're going to be doing everything with turns in numeric
# context. No sense in getting hammered by warnings about the conversion.

# TODO:
#   * An alternate function/module to parse AardvarkJoe's xlogfiles.

# Warning: Unless you're running a high-end computer, I wouldn't recommend
#          trying to fit huge logfiles through parse_file. Use parse_line if
#          possible. nethack.alt.org's multimegabyte logfile grinds my computer
#          to a halt.

package Logfile;

use strict;
use warnings;

my $logline = qr/^(\d\.\d\.\d) (\d+) (\d+) (-?\d+) (-?\d+) (-?\d+) (-?\d+) (\d+) (\d{8}) (\d{8}) (\d+) ([A-Z][a-z]{2}) ([A-Z][a-z]{2}) ([A-Z][a-z]{2}) ([A-Z][a-z]{2}) ([^,]+),(.+?)(?: {(\d+)})?$/;

{
  # Let's try to guess what the game ID and ascension number are. 
  # The caller can, of course, overwrite these values if he's doing his own thing.
  my $id = 0;
  my $ascension = 0;

  # We specifically reset when we run parse_contents or parse_file. User can do so as well.
  sub reset_numbers
  {
    $id = 0;
    $ascension = 0;
  }

  sub parse_line
  {
    my $line = shift;
    my $basic = shift || 0;
    my %game = ();
    
    chomp $line;
    
    my ($version, $score, $dnum, $curdlvl, $maxdlvl, $curhp, $maxhp, $deaths,
      $enddate, $startdate, $user, $role, $race, $gender, $align, $name, $death,
      $turns)
        = $line =~ $logline;

    defined $death or die "Unable to parse the following logfile line: $line";

    ++$id;
    $turns = 0 unless defined $turns;
    
    if (!$basic)
    {
      my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
      my ($lifesaved, $dchar, $dungeon, $bestdlvl, $ascended, $quit, $crga, $start, $end);
      
      $ascended = ($death eq 'ascended') ? 1 : 0;
      $quit = ($death eq 'quit' || $death eq 'quit (with the Amulet)' || $death eq 'escaped') ? 1 : 0;

      # Assume the player died, then correct it if he didn't.
      $lifesaved = $deaths - 1;
      $lifesaved++ if $ascended || $quit || $death eq 'a trickery' || $death eq 'escaped (in celestial disgrace)';

      ++$ascension if $ascended;

      # bestdlvl is the lowest level reached, or one of the Planes (but not Heaven)
      $bestdlvl = $maxdlvl;
      $bestdlvl = $curdlvl if $curdlvl < 0 && $curdlvl > -6;

      # "20051113" becomes "13 Nov 05"
      $start = substr($startdate, -2) . ' ' . $months[substr($startdate, -4, 2) - 1] . ' ' . substr($startdate, 2, 2);
      $end   = substr($enddate,   -2) . ' ' . $months[substr($enddate,   -4, 2) - 1] . ' ' . substr($enddate,   2, 2);

      $crga = "$role $race $gender $align";
    
      if ($dnum == 0)
      {
        $dchar   = 'D';
        $dungeon = 'The Dungeons of Doom';
      } 
      elsif ($dnum == 1)
      {
        $dchar = 'H'; # (Hell) -- G is too easily confused with the Gnomish Mines
        $dungeon = 'Gehennom';
      } 
      elsif ($dnum == 2)
      {
        $dchar   = 'M';
        $dungeon = 'The Gnomish Mines';
      } 
      elsif ($dnum == 3)
      {
        $dchar   = 'Q';
        $dungeon = 'The Quest';
      } 
      elsif ($dnum == 4)
      {
        $dchar   = 'S';
        $dungeon = 'Sokoban';
      } 
      elsif ($dnum == 5)
      {
        $dchar   = 'L';
        $dungeon = 'Fort Ludios';
      } 
      elsif ($dnum == 6)
      {
        $dchar   = 'V';
        $dungeon = 'Vlad\'s Tower';
      } 
      elsif ($dnum == 7)
      {
        $dchar = 'P';
        if ($curdlvl == -1)
        {
          $dungeon = 'The Plane of Earth';
        }
        elsif ($curdlvl == -2)
        {
          $dungeon = 'The Plane of Air';
        }
        elsif ($curdlvl == -3)
        {
          $dungeon = 'The Plane of Fire';
        }
        elsif ($curdlvl == -4)
        {
          $dungeon = 'The Plane of Water';
        }
        elsif ($curdlvl == -5)
        {
          $dungeon = 'The Astral Plane';
        }
      }

      %game =
      (
        crga      => $crga,
        bestdlvl  => $bestdlvl,
        dchar     => $dchar,
        dungeon   => $dungeon,
        lifesaved => $lifesaved,
        ascended  => $ascended,
        ascension => $ascended ? $ascension : 0,
        quit      => $quit,
        start     => $start,
        end       => $end,
      );
    }
    
    %game =
    (
      # the logfile line itself, without \n
      raw       => $line,

      # fields grabbed directly from the logfile
      version   => $version,
      score     => $score,
      dnum      => $dnum,
      curdlvl   => $curdlvl,
      maxdlvl   => $maxdlvl,
      curhp     => $curhp,
      maxhp     => $maxhp,
      deaths    => $deaths,
      enddate   => $enddate,
      startdate => $startdate,
      user      => $user,
      role      => $role,
      race      => $race,
      gender    => $gender,
      align     => $align,
      name      => $name,
      death     => $death,
      turns     => $turns,

      # everything else
      id        => $id,
      %game,
    );

   return %game;
  }
}

sub parse_contents
{
  my $logfile = shift;
  my $basic = shift;
  my @lines = split(/\n/, $logfile);
  my @games = ();

  reset_numbers;

  foreach my $line (@lines)
  {
    my %game = parse_line($line, $basic);
    push @games, \%game;
  }
  
  return @games;
}

sub parse_file
{
  my $logfile = shift || 'logfile';
  my $basic = shift;
  my @games = ();
  my $line;

  reset_numbers;

  open (LOGFILE, '<', $logfile) or die "unable to open $logfile: $!";

  while ($line = <LOGFILE>)
  {
    my %game = parse_line($line, $basic);
    push @games, \%game;
  }

  close LOGFILE;

  return @games;
}

1;
