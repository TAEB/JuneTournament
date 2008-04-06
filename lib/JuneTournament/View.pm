#!/usr/bin/env perl
package JuneTournament::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/' => page {
    h1 { "The June Tournament" }
    p {
        outs "Hi! I'm currently building up the site. In the meantime, you can ";
        hyperlink(
            label => "browse the source code",
            url => "http://sartak.org/code/index.cgi?r=JuneTournament;a=summary",
        );
        outs ".";
    }
};

template 'recent-ascensions' => sub {
    my $games = JuneTournament::Model::GameCollection->new;
    $games->limit_to_ascensions;
    $games->order_by(column => 'id', order => 'desc');
    $games->set_page_info(per_page => 10);
    show games => $games;
};

template 'recent-games' => sub {
    my $games = JuneTournament::Model::GameCollection->new;
    $games->unlimit;
    $games->order_by(column => 'id', order => 'desc');
    $games->set_page_info(per_page => 10);
    show games => $games;
};

template games => sub {
    my $self  = shift;
    my $games = shift;

    ul {
        for (@$games) {
            li { show game => $_ }
        }
    }
};

template game => sub {
    my $self = shift;
    my $game = shift;

    outs sprintf '%d. %s (%s), %d points, %s',
        $game->id,
        $game->player->name,
        $game->crga,
        $game->score,
        $game->death;
};

1;

