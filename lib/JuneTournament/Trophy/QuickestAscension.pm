#!/usr/bin/env perl
package JuneTournament::Trophy::QuickestAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';

sub rank_by { 'realtime' }

1;
