#!/usr/bin/env perl
package JuneTournament::View;
use strict;
use warnings;
use Jifty::View::Declare -base;
use Time::Duration;

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

    h3 { "Recent Ascensions" };
    render_region(
        path => 'recent-ascensions',
        name => 'recent-ascensions',
    );

    h3 { "Recent Games" };
    render_region(
        path => 'recent-games',
        name => 'recent-games',
    );
};

template 'recent-ascensions' => sub {
    my $games = JuneTournament::Model::GameCollection->new;
    $games->limit_to_ascensions;
    $games->order_by(column => 'id', order => 'desc');
    games($games);
};

template 'recent-games' => sub {
    my $games = JuneTournament::Model::GameCollection->new;
    $games->unlimit;
    $games->order_by(column => 'id', order => 'desc');
    games($games);
};

sub games {
    my $games = shift;

    my $page = (get 'page') || 1;
    $games->set_page_info(per_page => 10, current_page => $page);

    div {
        ul {
            for (@$games) {
                li { game($_) }
            }
        };
        if ($games->pager->previous_page) {
            hyperlink(
                label => " prev ",
                onclick => {
                    args => {
                        page => $games->pager->previous_page,
                    }
                }
            );
        }
        if ($games->pager->next_page) {
            hyperlink(
                label => " next ",
                onclick => {
                    args => {
                        page => $games->pager->next_page,
                    }
                }
            );
        }
    }
}

sub game {
    my $game = shift;

    my $display = sprintf '%d. %s (%s), %d points, %s%s',
        $game->id,
        $game->player->name,
        $game->crga,
        $game->score,
        $game->death,
        $game->endtime ? ' (' . ago(time - $game->endtime, 1) . ')' : '';

    if (my $url = $game->dumplog_url) {
        hyperlink(
            url => $url,
            label => $display,
        );
    }
    else {
        outs $display;
    }
}

1;

