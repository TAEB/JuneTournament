use strict;
use warnings;

package JuneTournament::Model::Player;
use Jifty::DBI::Schema;

use JuneTournament::Record schema {
    column name =>
        type is 'text',
        is mandatory,
        is distinct;
    column games =>
        refers_to JuneTournament::Model::GameCollection by 'player';
};

1;

