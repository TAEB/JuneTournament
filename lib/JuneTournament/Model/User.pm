package JuneTournament::Model::User;
use strict;
use warnings;
use LWP::Simple;

use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column name =>
        type is 'text',
        is mandatory,
        is distinct;
};

sub verify_token {
    my $self  = shift;
    my $token = shift;
    my $name  = $self->name;

    my $rcfile = get "http://alt.org/nethack/userdata/$name/$name.nh343rc";
    return index($rcfile, $token) > -1;
}

=head2 current_user_can

Anyone may create User objects. Only root and the given user may update a
User.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $right eq 'create';
    return 1 if $self->current_user->is_superuser;

    return $self->__value('id') == $self->current_user->id;
}

1;

