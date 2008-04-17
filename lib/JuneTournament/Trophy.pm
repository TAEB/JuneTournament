#!/usr/bin/env perl
package JuneTournament::Trophy;
use strict;
use warnings;

=head2 game_qualifies Game -> Bool

Does this game qualify for the trophy? (For example, if this trophy is for
ascensions only, was this game an ascension?)

=cut

sub game_qualifies { 1 }

=head2 incorporate_game Game

Add this game to the trophy's standings. This should not be overriden by child
classes.

=cut

sub incorporate_game {
    my $self = shift;
    my $game = shift;

}

1;

