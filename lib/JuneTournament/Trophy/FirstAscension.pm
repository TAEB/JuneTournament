#!/usr/bin/env perl
package JuneTournament::Trophy::FirstAscension;
use strict;
use warnings;
use parent 'JuneTournament::Trophy::SingleAscension';

sub rank_by { 'endtime' }
sub extra_display { gmtime($_->endtime) }

1;

