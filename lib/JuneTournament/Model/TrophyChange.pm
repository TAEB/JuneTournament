#!/usr/bin/env perl
package JuneTournament::Model::TrophyChange;
use strict;
use warnings;

use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column game =>
        refers_to JuneTournament::Model::Game,
        is mandatory;
    column trophy =>
        type is 'text',
        is mandatory,
        valid_values are JuneTournament->trophies;
    column rank =>
        type is 'int',
        is mandatory;
};

=head2 player

The player who played the game that made this trophy change

=cut

sub player { shift->game->player }

1;

