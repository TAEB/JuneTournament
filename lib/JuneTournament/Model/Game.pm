use strict;
use warnings;

package JuneTournament::Model::Game;
use Text::XLogfile 'parse_xlogline';
use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column player =>
        refers_to JuneTournament::Model::Player by 'name',
        is mandatory;
    column version =>
        type is 'text',
        is mandatory;
    column score =>
        type is 'int',
        is mandatory;
    column branch =>
        type is 'text',
        valid_values are qw(dungeons mines sokoban quest ludios gehennom vlad planes),
        is mandatory;
    column curlvl =>
        type is 'int',
        is mandatory;
    column maxlvl =>
        type is 'int',
        is mandatory;
    column curhp =>
        type is 'int',
        is mandatory;
    column maxhp =>
        type is 'int',
        is mandatory;
    column deaths =>
        type is 'int',
        is mandatory;
    column enddate =>
        type is 'text',
        is mandatory;
    column startdate =>
        type is 'text',
        is mandatory;
    column userid =>
        type is 'int',
        is mandatory;
    column class =>
        type is 'text',
        valid_values are qw(Arc Bar Cav Hea Kni Mon Pri Ran Rog Sam Tou Val Wiz),
        is mandatory;
    column race =>
        type is 'text',
        valid_values are qw(Hum Elf Orc Gno Dwa),
        is mandatory;
    column gender =>
        type is 'text',
        valid_values are qw(Mal Fem),
        is mandatory;
    column alignment =>
        type is 'text',
        valid_values are qw(Law Neu Cha),
        is mandatory;
    column death =>
        type is 'text',
        is mandatory;
    column ascended =>
        is boolean,
        default is 0,
        is mandatory;
    column conduct =>
        type is 'int',
        default is 0;
    column turns =>
        type is 'int',
        default is 0;
    column achievement =>
        type is 'int',
        default is 0;
    column realtime =>
        type is 'int',
        default is 0;
    column starttime =>
        type is 'int',
        default is 0;
    column endtime =>
        type is 'int',
        default is 0;
    column gender0 =>
        type is 'text';
    column align0 =>
        type is 'text';
};

=head2 current_user_can

Only root may update games. Any user may read games.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $right eq 'read';
    return $self->current_user->is_superuser;
}

=head2 xlogline_hashmap hashref -> hashref

Takes a hashref from parse_xlogline and returns a renamed one suitable for
passing to the model's create.

=cut

sub xlogline_hashmap {
    my $self = shift;
    my %in   = %{ shift @_ };
    my %out;

    my @same = qw/version maxlvl maxhp deaths race gender death conduct turns realtime starttime endtime gender0 align0/;

    my %map = (
        points    => 'score',
        deathdnum => 'branch',
        deathlev  => 'curlvl',
        hp        => 'curhp',
        uid       => 'userid',
        deathdate => 'enddate',
        birthdate => 'startdate',
        role      => 'class',
        align     => 'alignment',
        name      => 'player',
        achieve   => 'achievement',
    );

    @out{@same} = delete @in{@same};
    @out{values %map} = delete @in{keys %map};

    if (keys %in) {
        Carp::confess "Unknown keys: " . join(', ', keys %in)
    }

    return \%out;
}

=head2 hash_from_xlogline line -> hashref

Inflates the logline to a hash and maps the keys from the default xlogfile
keys to those expected by this model.

=cut

sub hash_from_xlogline {
    my $self = shift;
    my $line = shift;

    my $game = parse_xlogline($line);
    return $self->xlogline_hashmap($game);
}

=head2 create_from_xlogline line -> id, msg

Creates a new Game object from the given xlogline

=cut

sub create_from_xlogline {
    my $self = shift;
    my $line = shift;

    my $args = $self->hash_from_xlogline($line);
    $self->create(%$args);
}

=head2 before_create

Create the Player record if it doesn't already exist. Also, set the ascended
flag to whether the player ascended or not.

=cut

sub before_create {
    my $self = shift;
    my $args = shift;

    my $name = $args->{player};
    $name = $name->name if ref $name;

    my $player = JuneTournament::Model::Player->new;
    $player->load_or_create(
        name => $name,
    );

    $args->{ascended} = $args->{death} eq 'ascended';

    return 1;
}

=head2 canonicalize_branch

Turn numeric branch IDs into names.

=cut

sub canonicalize_branch {
    my $self = shift;
    my $branch = shift;

    if ($branch =~ m{^\d+$}) {
        my @branches = qw(dungeons gehennom mines quest sokoban ludios vlad planes);
        return $branches[$branch];
    }

    return $branch;
}

1;

