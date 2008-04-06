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
    column uid =>
        type is 'int',
        is mandatory;
    column role =>
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

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # anyone may read any data on a game
    return 1 if $right eq 'read';

    # only root may update game
    return $self->current_user->is_superuser;
}

sub xlogline_hashmap {
    my $self = shift;
    my %in   = %{ shift @_ };
    my %out;

    my @same = qw/version maxlvl maxhp deaths uid role race gender name death conduct turns realtime starttime endtime gender0 align0/;

    my %map = (
        points    => 'score',
        deathdnum => 'branch',
        deathlev  => 'curlvl',
        deathdate => 'enddate',
        birthdate => 'startdate',
        align     => 'alignment',
        achieve   => 'achievement',
    );

    @out{@same} = delete @in{@same};
    @out{values %map} = delete @in{keys %map};
    return \%out;
}

sub hash_from_xlogline {
    my $self = shift;
    my $line = shift;

    my $game = parse_xlogline($line);
    return $self->xlogline_hashmap($game);
}

sub new_from_xlogline {
    my $self = shift;
    my $line = shift;

    my $args = $self->hash_from_xlogline($line);
    $self->create(%$args);
}

1;

