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

    return $a->$field <=> $b->$field || $a->endtime <=> $b->endtime;
}

sub order_clause {
    my $self = shift;
    return (column => $self->rank_by);
}

sub rank_game {
    my $self = shift;
    my $game = shift;

    my $standings = $self->standings;

    return $standings->binary_search(sub {
        $self->compare_games($game, $_);
    });
}

sub standings {
    my $self = shift;
    my $ascensions = JuneTournament::Model::GameCollection->ascensions;

    # sort by $field, but break ties with endtime
    $ascensions->order_by(column => 'endtime');
    $ascensions->add_order_by($self->order_clause);

    return $ascensions;
}

1;

