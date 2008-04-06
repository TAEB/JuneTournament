use strict;
use warnings;

package JuneTournament::Model::Clan;
use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column name =>
        type is 'text',
        is mandatory,
        is distinct;
    column players =>
        refers_to JuneTournament::Model::PlayerCollection by 'clan';
};

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

