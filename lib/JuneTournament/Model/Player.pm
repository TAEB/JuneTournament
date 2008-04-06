use strict;
use warnings;

package JuneTournament::Model::Player;
use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column name =>
        type is 'text',
        is mandatory,
        is distinct;
    column games =>
        refers_to JuneTournament::Model::GameCollection by 'player';
};

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # anyone may read any data on a player
    return 1 if $right eq 'read';

    # only root may update players
    return $self->current_user->is_superuser;
}

1;

