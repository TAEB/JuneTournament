use strict;
use warnings;

package JuneTournament::Model::Player;
use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column name =>
        type is 'text',
        is mandatory,
        is distinct;
    column clan =>
        type is 'text',
        refers_to JuneTournament::Model::Clan by 'name';
};

=head2 games

Returns the GameCollection for this player

=cut

sub games {
    my $self = shift;
    my $games = JuneTournament::Model::GameCollection->new;
    $games->limit(column => 'player', value => $self->name);
    return $games;
}

=head2 current_user_can

Only root may update players. Any user may read players.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $right eq 'read';
    return $self->current_user->is_superuser;
}

=head2 ascensions

Returns the ascensions by the player.

=cut

sub ascensions {
    my $self = shift;
    my $games = $self->games;
    $games->limit(column => 'ascended', value => 1);
    return $games;
}

1;

