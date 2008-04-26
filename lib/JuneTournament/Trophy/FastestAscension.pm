#!/usr/bin/env perl
package JuneTournament::Trophy::FastestAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';

sub rank_by { 'turns' }
sub extra_display { 'T:' . $_[1]->turns }

1;

