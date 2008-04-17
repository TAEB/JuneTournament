package JuneTournament::Model::Clan;
use strict;
use warnings;

use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column name =>
        type is 'text',
        is mandatory,
        is distinct;
};

=head2 players

Returns the PlayerCollection for this clan

=cut

sub players {
    my $self = shift;
    my $players = JuneTournament::Model::PlayerCollection->new;
    $players->limit(column => 'clan', value => $self->name);
    return $players;
}

=head2 current_user_can

Only root may update clans. Any user may read clans.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $right eq 'read';
    return $self->current_user->is_superuser;
}

1;

