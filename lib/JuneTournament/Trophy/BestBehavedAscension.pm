#!/usr/bin/env perl
package JuneTournament::Trophy::BestBehavedAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';

sub rank_by { 'conducts' }

sub compare_games {
    my $self = shift;
    my ($a, $b) = @_;

    return $b->conducts <=> $a->conducts || $a->endtime <=> $b->endtime;
}

sub order_clause {
    my $self = shift;
    return (column => 'conducts', order => 'descending');
}

1;

