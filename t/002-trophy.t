#!/usr/bin/env perl
use Jifty::Test tests => 74;

my @games = split /\n/, << ".";
version=3.4.3:points=989206:deathdnum=7:deathlev=-5:maxlvl=53:hp=108:maxhp=125:deaths=0:deathdate=20080401:birthdate=20080330:uid=5:role=Rog:race=Hum:gender=Mal:align=Law:name=squidlarkin:death=ascended:conduct=0x480:turns=23377:achieve=0xfff:realtime=18217:starttime=1206887514:endtime=1207009643:gender0=Mal:align0=Cha
version=3.4.3:points=1333048:deathdnum=7:deathlev=-5:maxlvl=51:hp=120:maxhp=147:deaths=0:deathdate=20080401:birthdate=20080331:uid=5:role=Cav:race=Dwa:gender=Fem:align=Law:name=healthy:death=ascended:conduct=0x700:turns=20704:achieve=0x7ff:realtime=14242:starttime=1206996077:endtime=1207010342:gender0=Fem:align0=Law
version=3.4.3:points=1436332:deathdnum=7:deathlev=-5:maxlvl=50:hp=106:maxhp=231:deaths=0:deathdate=20080401:birthdate=20080401:uid=5:role=Val:race=Dwa:gender=Fem:align=Cha:name=healthy:death=ascended:conduct=0x500:turns=21124:achieve=0x7ff:realtime=13236:starttime=1207046410:endtime=1207090154:gender0=Fem:align0=Law
version=3.4.3:points=2172222:deathdnum=7:deathlev=-5:maxlvl=45:hp=250:maxhp=250:deaths=0:deathdate=20080402:birthdate=20080330:uid=5:role=Rog:race=Orc:gender=Mal:align=Cha:name=Mind:death=ascended:conduct=0x400:turns=67601:achieve=0xfff:realtime=123456:starttime=1206863611:endtime=1207133694:gender0=Mal:align0=Cha
version=3.4.3:points=3731952:deathdnum=7:deathlev=-5:maxlvl=51:hp=227:maxhp=249:deaths=0:deathdate=20080402:birthdate=20080331:uid=5:role=Bar:race=Hum:gender=Mal:align=Cha:name=BlackrayJack:death=ascended:conduct=0x0:turns=54576:achieve=0xdff:realtime=45134:starttime=1206927106:endtime=1207133842:gender0=Mal:align0=Cha
version=3.4.3:points=3139340:deathdnum=7:deathlev=-5:maxlvl=49:hp=423:maxhp=423:deaths=0:deathdate=20080402:birthdate=20080320:uid=5:role=Cav:race=Gno:gender=Mal:align=Neu:name=brooder:death=ascended:conduct=0x100:turns=55614:achieve=0xfff:realtime=130187:starttime=1206023642:endtime=1207159118:gender0=Mal:align0=Neu
version=3.4.3:points=4764936:deathdnum=7:deathlev=-5:maxlvl=49:hp=402:maxhp=406:deaths=0:deathdate=20080402:birthdate=20080321:uid=5:role=Val:race=Hum:gender=Fem:align=Law:name=SomeJerk:death=ascended:conduct=0x400:turns=85393:achieve=0xfff:realtime=68261:starttime=1206105282:endtime=1207163702:gender0=Fem:align0=Law
version=3.4.3:points=5976988:deathdnum=7:deathlev=-5:maxlvl=49:hp=461:maxhp=461:deaths=0:deathdate=20080403:birthdate=20080328:uid=5:role=Tou:race=Hum:gender=Mal:align=Neu:name=efot:death=ascended:conduct=0x100:turns=43990:achieve=0xfff:realtime=83822:starttime=1206666899:endtime=1207216759:gender0=Mal:align0=Neu
version=3.4.3:points=1636962:deathdnum=7:deathlev=-5:maxlvl=46:hp=110:maxhp=131:deaths=1:deathdate=20080403:birthdate=20080403:uid=5:role=Pri:race=Hum:gender=Mal:align=Law:name=healthy:death=ascended:conduct=0xc00:turns=19960:achieve=0xfff:realtime=12982:starttime=1207213435:endtime=1207226435:gender0=Mal:align0=Law
version=3.4.3:points=3655990:deathdnum=7:deathlev=-5:maxlvl=51:hp=181:maxhp=215:deaths=0:deathdate=20080403:birthdate=20080401:uid=5:role=Val:race=Hum:gender=Fem:align=Law:name=Beeze:death=ascended:conduct=0x580:turns=49544:achieve=0xfff:realtime=59119:starttime=1207054048:endtime=1207227459:gender0=Fem:align0=Law
version=3.4.3:points=2326424:deathdnum=7:deathlev=-5:maxlvl=46:hp=137:maxhp=137:deaths=0:deathdate=20080403:birthdate=20080330:uid=5:role=Val:race=Hum:gender=Fem:align=Cha:name=Perihelion:death=ascended:conduct=0xc00:turns=32576:achieve=0xfff:realtime=51670:starttime=1206840246:endtime=1207260953:gender0=Fem:align0=Law
version=3.4.3:points=1822564:deathdnum=7:deathlev=-5:maxlvl=52:hp=227:maxhp=238:deaths=2:deathdate=20080404:birthdate=20080401:uid=5:role=Rog:race=Orc:gender=Mal:align=Cha:name=YogLLJK:death=ascended:conduct=0x480:turns=28290:achieve=0x9ff:realtime=145371:starttime=1207008537:endtime=1207292530:gender0=Mal:align0=Cha
version=3.4.3:points=4357565:deathdnum=7:deathlev=-5:maxlvl=51:hp=345:maxhp=345:deaths=0:deathdate=20080404:birthdate=20080403:uid=5:role=Arc:race=Dwa:gender=Mal:align=Law:name=marmoset:death=ascended:conduct=0x500:turns=79160:achieve=0xfff:realtime=87036:starttime=1207189274:endtime=1207300071:gender0=Mal:align0=Law
version=3.4.3:points=3957520:deathdnum=7:deathlev=-5:maxlvl=47:hp=440:maxhp=440:deaths=0:deathdate=20080404:birthdate=20080402:uid=5:role=Tou:race=Hum:gender=Mal:align=Neu:name=Mind:death=ascended:conduct=0x0:turns=51072:achieve=0xfff:realtime=55957:starttime=1207159225:endtime=1207301621:gender0=Mal:align0=Neu
version=3.4.3:points=4274114:deathdnum=7:deathlev=-5:maxlvl=51:hp=269:maxhp=275:deaths=0:deathdate=20080404:birthdate=20080403:uid=5:role=Tou:race=Hum:gender=Mal:align=Neu:name=Eben:death=ascended:conduct=0x0:turns=56062:achieve=0xfff:realtime=69051:starttime=1207193798:endtime=1207309402:gender0=Mal:align0=Neu
version=3.4.3:points=4775008:deathdnum=7:deathlev=-5:maxlvl=45:hp=270:maxhp=306:deaths=0:deathdate=20080404:birthdate=20080401:uid=5:role=Val:race=Hum:gender=Fem:align=Neu:name=unicron:death=ascended:conduct=0x100:turns=51563:achieve=0xfff:realtime=131134:starttime=1207074876:endtime=1207319126:gender0=Fem:align0=Neu
version=3.4.3:points=1344812:deathdnum=7:deathlev=-5:maxlvl=50:hp=142:maxhp=170:deaths=0:deathdate=20080404:birthdate=20080403:uid=5:role=Ran:race=Elf:gender=Fem:align=Cha:name=squidlarkin:death=ascended:conduct=0x500:turns=31907:achieve=0xfff:realtime=34522:starttime=1207258466:endtime=1207328892:gender0=Fem:align0=Cha
version=3.4.3:points=1232858:deathdnum=7:deathlev=-5:maxlvl=48:hp=45:maxhp=146:deaths=0:deathdate=20080405:birthdate=20080404:uid=5:role=Bar:race=Hum:gender=Mal:align=Cha:name=Cesario:death=ascended:conduct=0x500:turns=18957:achieve=0x7ff:realtime=13143:starttime=1207349002:endtime=1207363119:gender0=Mal:align0=Cha
version=3.4.3:points=4883656:deathdnum=7:deathlev=-5:maxlvl=50:hp=460:maxhp=460:deaths=1:deathdate=20080405:birthdate=20080323:uid=5:role=Mon:race=Hum:gender=Fem:align=Cha:name=Netrarc:death=ascended:conduct=0x0:turns=68844:achieve=0xfff:realtime=121210:starttime=1206282303:endtime=1207384180:gender0=Fem:align0=Cha
version=3.4.3:points=4196550:deathdnum=7:deathlev=-5:maxlvl=50:hp=202:maxhp=209:deaths=0:deathdate=20080405:birthdate=20080402:uid=5:role=Wiz:race=Hum:gender=Mal:align=Neu:name=rcxdude:death=ascended:conduct=0x500:turns=88705:achieve=0xfff:realtime=228216:starttime=1207141169:endtime=1207400677:gender0=Mal:align0=Neu
version=3.4.3:points=6146356:deathdnum=7:deathlev=-5:maxlvl=53:hp=399:maxhp=460:deaths=3:deathdate=20080405:birthdate=20080330:uid=5:role=Sam:race=Hum:gender=Fem:align=Law:name=solidsnail:death=ascended:conduct=0xfc8:turns=93441:achieve=0xfff:realtime=112648:starttime=1206872024:endtime=1207413992:gender0=Fem:align0=Law
version=3.4.3:points=7645364:deathdnum=7:deathlev=-5:maxlvl=49:hp=298:maxhp=305:deaths=0:deathdate=20080405:birthdate=20080323:uid=5:role=Wiz:race=Hum:gender=Fem:align=Neu:name=Qwkfinger:death=ascended:conduct=0x0:turns=40170:achieve=0xfff:realtime=105800:starttime=1206302592:endtime=1207418195:gender0=Fem:align0=Neu
version=3.4.3:points=3532272:deathdnum=7:deathlev=-5:maxlvl=48:hp=325:maxhp=325:deaths=0:deathdate=20080405:birthdate=20080322:uid=5:role=Val:race=Hum:gender=Fem:align=Law:name=meetcodewalker:death=ascended:conduct=0x180:turns=52508:achieve=0xfff:realtime=770609:starttime=1206204595:endtime=1207425682:gender0=Fem:align0=Law
version=3.4.3:points=3933236:deathdnum=7:deathlev=-5:maxlvl=48:hp=128:maxhp=247:deaths=0:deathdate=20080405:birthdate=20080404:uid=5:role=Cav:race=Dwa:gender=Mal:align=Law:name=Eben:death=ascended:conduct=0x100:turns=50086:achieve=0xfff:realtime=62017:starttime=1207314314:endtime=1207426702:gender0=Mal:align0=Law
version=3.4.3:points=2591798:deathdnum=7:deathlev=-5:maxlvl=52:hp=264:maxhp=303:deaths=0:deathdate=20080405:birthdate=20080401:uid=5:role=Bar:race=Orc:gender=Fem:align=Cha:name=spaps:death=ascended:conduct=0xd80:turns=35248:achieve=0xbff:realtime=38993:starttime=1207019731:endtime=1207427924:gender0=Fem:align0=Cha
version=3.4.3:points=2056580:deathdnum=7:deathlev=-5:maxlvl=50:hp=211:maxhp=211:deaths=0:deathdate=20080405:birthdate=20080403:uid=5:role=Mon:race=Hum:gender=Fem:align=Law:name=Perihelion:death=ascended:conduct=0x100:turns=38828:achieve=0xfff:realtime=60384:starttime=1207261168:endtime=1207439282:gender0=Fem:align0=Cha
version=3.4.3:points=2324386:deathdnum=7:deathlev=-5:maxlvl=50:hp=96:maxhp=136:deaths=0:deathdate=20080406:birthdate=20080324:uid=5:role=Wiz:race=Elf:gender=Mal:align=Cha:name=pennypeckr:death=ascended:conduct=0x580:turns=33470:achieve=0xfff:realtime=39682:starttime=1206366172:endtime=1207440474:gender0=Mal:align0=Cha
version=3.4.3:points=6217060:deathdnum=7:deathlev=-5:maxlvl=46:hp=447:maxhp=492:deaths=0:deathdate=20080406:birthdate=20080403:uid=5:role=Pri:race=Hum:gender=Fem:align=Law:name=Thyra:death=ascended:conduct=0xc80:turns=67278:achieve=0xfff:realtime=63071:starttime=1207247398:endtime=1207444839:gender0=Fem:align0=Neu
version=3.4.3:points=1283338:deathdnum=7:deathlev=-5:maxlvl=47:hp=137:maxhp=164:deaths=0:deathdate=20080406:birthdate=20080405:uid=5:role=Pri:race=Elf:gender=Mal:align=Cha:name=squidlarkin:death=ascended:conduct=0x580:turns=26390:achieve=0xfff:realtime=17569:starttime=1207428373:endtime=1207457467:gender0=Mal:align0=Cha
version=3.4.3:points=3074386:deathdnum=7:deathlev=-5:maxlvl=45:hp=246:maxhp=248:deaths=0:deathdate=20080406:birthdate=20080405:uid=5:role=Bar:race=Hum:gender=Mal:align=Cha:name=Eben:death=ascended:conduct=0x100:turns=48737:achieve=0xfff:realtime=65658:starttime=1207427239:endtime=1207496907:gender0=Mal:align0=Cha
version=3.4.3:points=2754476:deathdnum=7:deathlev=-5:maxlvl=50:hp=146:maxhp=247:deaths=0:deathdate=20080406:birthdate=20080328:uid=5:role=Val:race=Dwa:gender=Fem:align=Law:name=munsonea:death=ascended:conduct=0x980:turns=40122:achieve=0xfff:realtime=28608:starttime=1206669502:endtime=1207500080:gender0=Fem:align0=Law
version=3.4.3:points=14610466:deathdnum=7:deathlev=-5:maxlvl=50:hp=463:maxhp=463:deaths=0:deathdate=20080406:birthdate=20080401:uid=5:role=Wiz:race=Orc:gender=Mal:align=Cha:name=nopsled:death=ascended:conduct=0x500:turns=60614:achieve=0xfff:realtime=72763:starttime=1207071559:endtime=1207506013:gender0=Mal:align0=Cha
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

