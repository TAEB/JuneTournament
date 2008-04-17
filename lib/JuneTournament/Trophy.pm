#!/usr/bin/env perl
package JuneTournament::Trophy;
use strict;
use warnings;

=head2 game_qualifies Game -> Bool

Does this game qualify for the trophy? (For example, if this trophy is for
ascensions only, was this game an ascension?)

=cut

sub game_qualifies { 1 }

1;

