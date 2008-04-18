#!/usr/bin/env perl
package JuneTournament::Trophy::LowestScoringAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';

sub rank_by { 'score' }
sub extra_display { 'S:' . $_->score }

1;

