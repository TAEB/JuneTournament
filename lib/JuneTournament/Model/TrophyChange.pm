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
    column endtime =>
        type is 'int',
        is mandatory;
};

=head2 player

The player who played the game that made this trophy change

=cut

sub player { shift->game->player }

=head2 current_user_can

Only root may update trophy changes. Any user may read trophy changes.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $right eq 'read';
    return $self->current_user->is_superuser;
}

1;

