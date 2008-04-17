#!/usr/bin/env perl
package JuneTournament::Trophy::BestBehavedAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';

sub rank_by { 'conducts' }

sub compare_games {
    my $self = shift;
    my ($a, $b) = @_;

    $b->conducts <=> $a->conducts
}

1;

