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

sub rank_game {
    my $self = shift;
    my $game = shift;

    my $ascensions = JuneTournament::Model::GameCollection->ascensions;
    $ascensions->order_by(column => 'endtime');

    return $ascensions->binary_search(sub { $game->endtime <=> $_->endtime });
}

1;

