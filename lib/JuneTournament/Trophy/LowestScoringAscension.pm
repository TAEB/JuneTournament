#!/usr/bin/env perl
package JuneTournament::Trophy::LowestScoringAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';

sub rank_by { 'score' }

1;
