#!/usr/bin/env perl
package JuneTournament::Trophy::SingleAscension;
use strict;
use warnings;

sub game_qualifies {
    my $self = shift;
    my $game = shift;

    return $game->ascended;
}

sub rank_game {
    my $self = shift;
    my $game = shift;
    my $field = $self->rank_by;

    my $ascensions = JuneTournament::Model::GameCollection->ascensions;
    $ascensions->order_by(column => $field);

    return $ascensions->binary_search(sub { $game->$field <=> $_->$field });
}

1;

