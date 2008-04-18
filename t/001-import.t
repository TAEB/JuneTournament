#!/usr/bin/env perl
use Jifty::Test tests => 74;

my $xlogline = <<"END";
version=3.4.3:points=8408:deathdnum=2:deathlev=7:maxlvl=7:hp=-2:maxhp=63:deaths=1:deathdate=20080326:birthdate=20080324:uid=5:role=Wiz:race=Hum:gender=Mal:align=Neu:name=mangotiger:death=killed by a soldier ant:conduct=0xf80:turns=4659:achieve=0x0:realtime=10690:starttime=1206392007:endtime=1206504538:gender0=Mal:align0=Neu
END

my $args = JuneTournament::Model::Game->hash_from_xlogline($xlogline);
my $expected = {
    version     => '3.4.3',
    score       => 8408,
    branch      => 2,
    curlvl      => 7,
    maxlvl      => 7,
    curhp       => -2,
    maxhp       => 63,
    deaths      => 1,
    enddate     => 20080326,
    startdate   => 20080324,
    userid      => 5,
    class       => 'Wiz',
    race        => 'Hum',
    gender      => 'Mal',
    alignment   => 'Neu',
    player      => 'mangotiger',
    death       => 'killed by a soldier ant',
    conduct     => '0xf80',
    turns       => 4659,
    achievement => '0x0',
    realtime    => 10690,
    starttime   => 1206392007,
    endtime     => 1206504538,
    gender0     => 'Mal',
    alignment0  => 'Neu',
};

is_deeply($args, $expected, "parsed the game to the correct hash");

my $game = JuneTournament::Model::Game->new(current_user => JuneTournament::CurrentUser->superuser);
my ($id, $msg) = $game->create(%$args);
ok($id, "Game was created ($msg)");
ok(!$game->ascended, "Game's ascended flag is off");
is($game->branch, 'mines', "Game ended in the mines");
is($game->player->name, 'mangotiger', "our friend mangotiger");
is($game->alignment, 'Neu', "neutral alignment");

my $player = JuneTournament::Model::Player->new(current_user => JuneTournament::CurrentUser->superuser);
$player->load_by_cols(name => 'mangotiger');
ok($player->id, "player was automatically created by the game");

$game = JuneTournament::Model::Game->new(current_user => JuneTournament::CurrentUser->superuser);
($id, $msg) = $game->create_from_xlogline("version=3.4.3:points=31791:deathdnum=2:deathlev=12:maxlvl=12:hp=-3:maxhp=84:deaths=1:deathdate=20080324:birthdate=20080323:uid=5:role=Wiz:race=Hum:gender=Mal:align=Neu:name=mangotiger:death=killed by a mountain centaur:conduct=0xf80:turns=9606:achieve=0x600:realtime=35547:starttime=1206294411:endtime=1206391854:gender0=Mal:align0=Neu");
ok($id, "Game was created ($msg)");
ok(!$game->ascended, "Game's ascended flag is off");
is($game->branch, 'mines', "Game ended in the mines");
is($game->player->name, 'mangotiger', "our friend mangotiger");
is($game->alignment, 'Neu', "neutral alignment");

my $players = JuneTournament::Model::PlayerCollection->new(current_user => JuneTournament::CurrentUser->superuser);
$players->unlimit;
is($players->count, 1, "only one instance of mangotiger");

$game = JuneTournament::Model::Game->new(current_user => JuneTournament::CurrentUser->superuser);
($id, $msg) = $game->create_from_xlogline("version=3.4.3:points=1283338:deathdnum=7:deathlev=-5:maxlvl=47:hp=137:maxhp=164:deaths=0:deathdate=20080406:birthdate=20080405:uid=5:role=Pri:race=Elf:gender=Mal:align=Cha:name=squidlarkin:death=ascended:conduct=0x580:turns=26390:achieve=0xfff:realtime=17569:starttime=1207428373:endtime=1207457467:gender0=Mal:align0=Cha");
ok($id, "Game was created ($msg)");
is($game->death, 'ascended', "Game ended in ascension");
ok($game->ascended, 'ascended flag is on');
is($game->branch, 'planes', "Game ended in the planes");
is($game->player->name, 'squidlarkin', "our friend squidlarkin");
is($game->alignment, 'Cha', "chaotic alignment");

$game = JuneTournament::Model::Game->new(current_user => JuneTournament::CurrentUser->superuser);
($id, $msg) = $game->create_from_xlogline("align=Law:birthdate=20011024:death=killed by a brown mold:deathdate=20011024:deathdnum=0:deathlev=2:deaths=1:gender=Mal:hp=-2:maxhp=25:maxlvl=2:name=jkm:points=360:race=Hum:role=Sam:uid=1031:version=3.3.1");
ok($id, "Game was created ($msg)");
is($game->death, 'killed by a brown mold', "Death reason");
ok(!$game->ascended, 'ascended flag is off');
is($game->branch, 'dungeons', "Game ended in the main dungeons");
is($game->gender, 'Mal', "end gender was Mal");
is($game->gender0, 'Mal', "start gender defaults to end gender");
is($game->alignment, 'Law', "end alignment was Law");
is($game->alignment0, 'Law', "start alignment defaults to end alignment");
is($game->player->name, 'jkm', "our friend jkm");

$game = JuneTournament::Model::Game->new(current_user => JuneTournament::CurrentUser->superuser);
($id, $msg) = $game->create_from_xlogline("version=3.4.3:points=6217060:deathdnum=7:deathlev=-5:maxlvl=46:hp=447:maxhp=492:deaths=0:deathdate=20080406:birthdate=20080403:uid=5:role=Pri:race=Hum:gender=Fem:align=Law:name=Thyra:death=ascended:conduct=0xc80:turns=67278:achieve=0xfff:realtime=63071:starttime=1207247398:endtime=1207444839:gender0=Mal:align0=Neu");
ok($id, "Game was created ($msg)");
is($game->death, 'ascended', "Death reason");
ok($game->ascended, 'ascended flag is on');
is($game->branch, 'planes', "Game ended in the planes");
is($game->gender, 'Fem', "end gender was Fem");
is($game->gender0, 'Mal', "start gender was Mal");
is($game->alignment, 'Law', "end alignment was Law");
is($game->alignment0, 'Neu', "start alignment was Neu");
is($game->player->name, 'Thyra', "our friend Thyra");

$player = JuneTournament::Model::Player->new(current_user => JuneTournament::CurrentUser->superuser);
$player->load_by_cols(name => 'mangotiger');
is($player->games->count, 2, "two games by mangotiger");
is($player->ascensions->count, 0, "no ascensions by mangotiger");

for my $trophy (qw/FastestAscension FirstAscension QuickestAscension BestBehavedAscension LowestScoringAscension/) {
    my $changes = JuneTournament::Model::TrophyChangeCollection->new;
    $changes->limit(column => 'trophy', value => $trophy);
    is($changes->count, 2, "two changes made to $trophy");

    my $first = <$changes>;
    ok($first->id, "$trophy: first change has an ID");
    is($first->rank, 1, "$trophy: first change made someone into a first place winner");
    is($first->game->player->name, 'squidlarkin', "$trophy: player of the first game");

    my $second = <$changes>;
    ok($second->id, "$trophy: second change has an ID");
    is($second->game->player->name, 'Thyra', "$trophy: player of the second game");

    my $trophy_class = "JuneTournament::Trophy::$trophy";
    my $cmp = $trophy_class->compare_games($first->game, $second->game);
    my $ok;

    if ($cmp <= 0) {
        $ok = is($second->rank, 2, "$trophy: change made Thyra into the second place runner-up");
    }
    else {
        $ok = is($second->rank, 1, "$trophy: change made Thyra into the new first-place winner");
    }

    if (!$ok) {
        if ($trophy_class->can('rank_by')) {
            my $field = $trophy_class->rank_by;
            diag "1st game's $field: " . $first->game->$field;
            diag "2nd game's $field: " . $second->game->$field;
        }
    }
}

