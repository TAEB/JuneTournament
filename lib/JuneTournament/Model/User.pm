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
    my $name  = shift || $self->name;

    my $rcfile = get "http://alt.org/nethack/userdata/$name/$name.nh343rc";
    return undef if !defined($rcfile);
    return index($rcfile, $token) > -1 ? 1 : 0;
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

sub validate_name {
    my $self = shift;
    my $name = shift;

    return 0 if $name =~ /[^a-zA-Z0-9]/;
    return 0 if length($name) > 10;
    return 1;
}

1;

