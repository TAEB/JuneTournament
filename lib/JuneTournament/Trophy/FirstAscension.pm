#!/usr/bin/env perl
package JuneTournament::Trophy::FirstAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy';

sub game_qualifies {
    my $self = shift;
    my $game = shift;

    return $game->ascended;
}

1;

