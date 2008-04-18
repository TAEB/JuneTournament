#!/usr/bin/env perl
package JuneTournament::Trophy::SingleAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy';

sub game_qualifies {
    my $self = shift;
    my $game = shift;

    return $game->ascended;
}

sub compare_games {
    my $self = shift;
    my ($a, $b) = @_;
    my $field = $self->rank_by;

    $a->$field <=> $b->$field
}

sub rank_game {
    my $self = shift;
    my $game = shift;
    my $field = $self->rank_by;

    my $ascensions = JuneTournament::Model::GameCollection->ascensions;

    # sort by $field, but break ties with endtime
    $ascensions->order_by(column => 'endtime');
    $ascensions->add_order_by(column => $field);

    return $ascensions->binary_search(sub { $self->compare_games($game, $_) });
}

1;

