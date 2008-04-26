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
    my $lo = 0;
    my $hi = $standings->count - 1;

    while ($lo <= $hi) {
        my $i = int(($lo + $hi) / 2);

        $standings->set_page_info(
            current_page => $i + 1,
            per_page     => 1,
        );
        my $other = <$standings>;

        if ($other->id == $game->id) {
            return $i + 1;
        }

        my $cmp = $self->compare_games($game, $other);
        if ($cmp > 0) {
            $lo = $i + 1;
        }
        else {
            $hi = $i - 1;
        }
    }

    warn "Fell off rank_game looking for game #" . $game->id;
}

sub standings {
    my $self = shift;
    my $ascensions = JuneTournament::Model::GameCollection->ascensions;
    $ascensions->unshift_order_by($self->order_clause);

    return $ascensions;
}

1;

