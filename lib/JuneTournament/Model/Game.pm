use strict;
use warnings;

package JuneTournament::Model::Game;
use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column player =>
        refers_to JuneTournament::Model::Player by 'name';
    column version =>
        type is 'text';
    column score =>
        type is 'int';
    column branch =>
        type is 'text',
        valid_values are qw(dungeons mines sokoban quest ludios gehennom vlad planes);
    column curlvl =>
        type is 'int';
    column maxlvl =>
        type is 'int';
    column curhp =>
        type is 'int';
    column maxhp =>
        type is 'int';
    column deaths =>
        type is 'int';
    column enddate =>
        type is 'text';
    column startdate =>
        type is 'text';
    column uid =>
        type is 'int';
    column role =>
        type is 'text',
        valid_values are qw(Arc Bar Cav Hea Kni Mon Pri Ran Rog Sam Tou Val Wiz);
    column race =>
        type is 'text',
        valid_values are qw(Hum Elf Orc Gno Dwa);
    column gender =>
        type is 'text',
        valid_values are qw(Mal Fem);
    column alignment =>
        type is 'text',
        valid_values are qw(Law Neu Cha);
    column death =>
        type is 'text';
    column ascended =>
        is boolean;
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

1;

