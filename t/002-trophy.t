#!/usr/bin/env perl
use Jifty::Test tests => 74;

my @games = split /\n/, << ".";
version=3.4.3:points=1283338:deathdnum=7:deathlev=-5:maxlvl=47:hp=137:maxhp=164:deaths=0:deathdate=20080406:birthdate=20080405:uid=5:role=Pri:race=Elf:gender=Mal:align=Cha:name=squidlarkin:death=ascended:conduct=0x580:turns=26390:achieve=0xfff:realtime=17569:starttime=1207428373:endtime=1207457467:gender0=Mal:align0=Cha
version=3.4.3:points=6217060:deathdnum=7:deathlev=-5:maxlvl=46:hp=447:maxhp=492:deaths=0:deathdate=20080406:birthdate=20080403:uid=5:role=Pri:race=Hum:gender=Fem:align=Law:name=Thyra:death=ascended:conduct=0xc80:turns=67278:achieve=0xfff:realtime=63071:starttime=1207247398:endtime=1207444839:gender0=Mal:align0=Neu
.

for (@games) {
    my ($id, $msg) = JuneTournament::Model::Game->create_from_xlogline($_);
    ok($id, "created a game: $msg");
}

for my $trophy (qw/FastestAscension FirstAscension QuickestAscension BestBehavedAscension LowestScoringAscension/) {
    my $trophy_class = "JuneTournament::Trophy::$trophy";

    my $changes = JuneTournament::Model::TrophyChangeCollection->new;
    $changes->limit(column => 'trophy', value => $trophy);
    is($changes->count, @games, @games . " changes made to $trophy");

    my $first = <$changes>;
    ok($first->id, "$trophy: first change has an ID");
    is($first->rank, 1, "$trophy: first change made someone into a first place winner");

    my @standings = $first;

    while (my $change = <$changes>) {
        @standings = sort { $trophy_class->compare_games($a->game, $b->game) }
                     @standings, $change;

        my $rank;
        for (@standings) {
            if ($_->id == $change->id) {
                $rank = $_->rank;
                last;
            }
        }

        ok($rank, "got a rank ($rank)");
    }
}

