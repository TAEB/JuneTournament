package JuneTournament::Model::Game;
use strict;
use warnings;

use Text::XLogfile 'parse_xlogline';
use Scalar::Util 'blessed';

use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column player =>
        type is 'text',
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
    column conducts =>
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
    column alignment0 =>
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

    my @same = qw/version maxlvl maxhp deaths race gender death conduct turns realtime starttime endtime gender0/;

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
        align0    => 'alignment0',
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

    my $new = $self->new(current_user => JuneTournament::CurrentUser->superuser);
    my $args = $new->hash_from_xlogline($line);
    my @ret = $new->create(%$args);

    $self->load($new->id)
        if blessed $self;

    return @ret;
}

=head2 before_create

Create the Player record if it doesn't already exist. Also, set the ascended
flag to whether the player ascended or not. And default gender0 and alignment0.

=cut

sub before_create {
    my $self = shift;
    my $args = shift;

    if (my $prefix = Jifty->config->app('date_prefix')) {
        for my $field (qw/startdate enddate/) {
            return (0, "Invalid $field.")
                if substr($args->{$field}, 0, length($prefix)) ne $prefix;
        }
    }

    my $name = $args->{player};
    $name = $name->name if ref $name;

    my $player = JuneTournament::Model::Player->new;
    $player->load_or_create(
        name => $name,
    );

    $args->{ascended}     = $args->{death} eq 'ascended';
    $args->{gender0}    ||= $args->{gender};
    $args->{alignment0} ||= $args->{alignment};

    $args->{conducts}     = $args->{conduct}
                          ? $self->demunge_conduct($args->{conduct})
                          : 0;

    return 1;
}

=head2 create

Immediately incorporate this game into trophy calculations. We can't use the
"after_create" trigger because that fires before C<$self> is populated.

=cut

sub create {
    my $self = shift;
    $self->SUPER::create(@_);

    JuneTournament->incorporate_game_into_trophies($self);

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

=head2 role

Alias for class

=cut

sub role {
    my $self = shift;
    $self->class(@_);
}

=head2 crga

Returns the role race gender alignment of the game.

=cut

sub crga {
    my $self = shift;
    return join ' ', $self->role, $self->race, $self->gender, $self->alignment;
}

=head2 dumplog_url

Returns the URL to the game's dumplog. Assumes the tournament is being run on
NAO. If no starttime is in the game, then returns undef, because we won't be
able to find the url.

=cut

sub dumplog_url {
    my $self = shift;
    return unless $self->starttime;
    return sprintf 'http://alt.org/nethack/userdata/%s/dumplog/%d.nh343.txt',
                   $self->player->name,
                   $self->starttime;
}

sub canonicalize_conduct {
    my $self = shift;
    my $hex  = shift;

    return $hex if !defined($hex);

    if ($hex =~ /x/) {
        return hex $hex;
    }
    return $hex;
}

sub canonicalize_achievement {
    my $self = shift;
    my $hex  = shift;

    return $hex if !defined($hex);

    if ($hex =~ /x/) {
        return hex $hex;
    }
    return $hex;
}

my @conducts = (
    [foodless     => 0x0001],
    [vegan        => 0x0002],
    [vegetarian   => 0x0004],
    [atheist      => 0x0008],
    [weaponless   => 0x0010],
    [pacifist     => 0x0020],
    [illiterate   => 0x0040],
    [polyitemless => 0x0080],
    [polyselfless => 0x0100],
    [wishless     => 0x0200],
    [artiwishless => 0x0400],
    [genoless     => 0x0800],
);

sub demunge_conduct {
    my $self    = shift;
    my $conduct = shift || $self->conduct;
    my @achieved;

    foreach (@conducts) {
        push @achieved, $_->[0] if $conduct & $_->[1];
    }

    return @achieved;
}

sub conducts { shift->demunge_conduct }

1;

