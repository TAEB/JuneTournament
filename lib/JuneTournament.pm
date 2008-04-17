#!/usr/bin/env perl
package JuneTournament;
use strict;
use warnings;
use JuneTournament::Trophy::FirstAscension;

sub player {
    my $self = shift;
    my $name = shift;

    my $player = JuneTournament::Model::Player->new;
    $player->load_by_cols(name => $name);
    return $player->id ? $player : undef;
}

# good enough for now
sub trophies {
    return ("Best of 13", "Most Ascensions", "Fastest Ascension: Turns", "Fastest Ascension: Realtime", "Lowest-Scored Ascension", "Best Behaved Ascension", "First Ascension");
}

sub incorporate_game_into_trophies {
    my $self = shift;
    my $game = shift;

    for my $trophy (qw/FirstAscension/) {
        my $class = "JuneTournament::Trophy::$trophy";
        my $rank = $class->find_rank($game);

        if (defined $rank) {
            my $change = JuneTournament::Model::TrophyChange->new(current_user => JuneTournament::CurrentUser->superuser);

            $change->create(
                game   => $game,
                rank   => $rank,
                trophy => $trophy,
            );
        }
    }
}

1;

