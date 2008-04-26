#!/usr/bin/env perl
package JuneTournament;
use strict;
use warnings;

our @trophies = sort qw/FastestAscension FirstAscension QuickestAscension BestBehavedAscension LowestScoringAscension/;
for (@trophies) {
    require "JuneTournament/Trophy/$_.pm";
}

sub player {
    my $self = shift;
    my $name = shift;

    my $player = JuneTournament::Model::Player->new;
    $player->load_by_cols(name => $name);
    return $player->id ? $player : undef;
}

sub trophies { @trophies }

sub incorporate_game_into_trophies {
    my $self = shift;
    my $game = shift;

    for my $trophy ($self->trophies) {
        my $class = "JuneTournament::Trophy::$trophy";
        my $rank = $class->find_rank($game);

        if (defined $rank) {
            my $change = JuneTournament::Model::TrophyChange->new(current_user => JuneTournament::CurrentUser->superuser);

            $change->create(
                game    => $game,
                rank    => $rank,
                trophy  => $trophy,
                endtime => $game->endtime,
            );
        }
    }
}

1;

