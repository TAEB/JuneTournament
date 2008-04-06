#!/usr/bin/env perl
package JuneTournament;
use strict;
use warnings;

sub player {
    my $self = shift;
    my $name = shift;

    my $player = JuneTournament::Model::Player->new;
    $player->load_by_cols(name => $name);
    return $player->id ? $player : undef;
}

1;

