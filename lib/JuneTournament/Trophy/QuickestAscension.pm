#!/usr/bin/env perl
package JuneTournament::Trophy::QuickestAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';
use Time::Duration;

sub rank_by { 'realtime' }
sub extra_display { concise(duration($_->realtime)) }

1;

