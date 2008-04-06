#!/usr/bin/env perl
use Jifty::Test tests => 3;

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
    align0      => 'Neu',
};

is_deeply($args, $expected, "parsed the game to the correct hash");

my $game = JuneTournament::Model::Game->new(current_user => JuneTournament::CurrentUser->superuser);
my ($id, $msg) = $game->create(%$args);
ok($id, "Game was created");

my $player = JuneTournament::Model::Player->new(current_user => JuneTournament::CurrentUser->superuser);
$player->load_by_cols(name => 'mangotiger');
ok($player->id, "player was automatically created by the game");

