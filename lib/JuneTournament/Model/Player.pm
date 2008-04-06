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
    column clan =>
        type is 'text',
        refers_to JuneTournament::Model::Clan by 'name';
};

=head2 current_user_can

Only root may update players. Any user may read players.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $right eq 'read';
    return $self->current_user->is_superuser;
}

1;

