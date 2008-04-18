#!/usr/bin/env perl
package JuneTournament::View;
use strict;
use warnings;
use Jifty::View::Declare -base;
use Time::Duration;

template '/' => page {
    h1 { "The June Tournament" }
    p { "Hi!" }
    p {
        outs "I'm currently building up the site using this month's data from NAO. In the meantime, you can ";
        hyperlink(
            label => "browse the source code",
            url => "http://sartak.org/code/index.cgi?r=JuneTournament;a=summary",
        );
        outs ".";
    }

    h3 { "Recent Ascensions" };
    render_region(
        path => '/region/recent_ascensions',
        name => 'recent_ascensions',
    );

    h3 { "Recent Games" };
    render_region(
        path => '/recent_games',
        name => 'recent_games',
    );
};

template '/player' => page {
    my $name = get('name') || redirect('/errors/404');
    my $player = JuneTournament->player($name) || redirect('/errors/404');
    $name = $player->name;

    h1 { $name };

    if ($player->ascensions->count) {
        h3 { "Recent Ascensions" };
        render_region(
            path => '/player_ascs',
            name => 'player_ascs',
            arguments => {
                name => $name,
            },
        );
    }

    h3 { "Recent Games" };
    render_region(
        path => '/player_games',
        name => 'player_games',
        arguments => {
            name => $name,
        },
    );
};

template '/trophy' => page {
    my $name = get('name') || redirect('/errors/404');
    h1 { $name };

    h3 { "Winners" };
    render_region(
        path => '/region/trophy',
        name => 'trophy_games',
        arguments => {
            name => $name,
        },
    );
};

template '/region/recent_ascensions' => sub {
    games(ascended => 1);
};

template '/recent_games' => sub {
    games();
};

template '/player_ascs' => sub {
    games(ascended => 1, player => get('name'));
};

template '/player_games' => sub {
    games(player => get('name'));
};

template '/scums' => sub {
    games(
        [column => 'score', value => '1000', operator => '<'],
        death => 'quit',
        death => 'escaped',
    );
};

template '/region/trophy' => sub {
    my $name = get('name') || redirect('/errors/404');
    games(trophy => $name);
};

sub games {
    my $games;
    my $extra_display;

    # if they pass in exactly one arg, it's a game object
    if (@_ == 1) {
        $games = shift;
    }
    else {
        $games = JuneTournament::Model::GameCollection->new;
        $games->unlimit if @_ == 0;

        while (@_) {
            my $column = shift;
            if (ref($column) eq 'ARRAY') {
                $games->limit(@$column);
            }
            else {
                my $value = shift;

                if ($column eq 'trophy') {
                    my $class = "JuneTournament::Trophy::$value";
                    $class->can('find_rank') || redirect('/errors/404');
                    $games = $class->standings;
                    $extra_display = sub { $class->extra_display($_) }
                        if $class->can('extra_display');
                }
                else {
                    $games->limit(column => $column, value => $value);
                }
            }
        }
    }

    my $page = (get 'page') || 1;
    $games->set_page_info(per_page => 10, current_page => $page);

    div {
        ul {
            for (@$games) {
                li {
                    outs game($_);
                    outs ' - ' . $extra_display->() if $extra_display;
                }
            }
        };
        paging($games);
    }
}

sub game {
    my $game = shift;

    span {
        outs $game->id . '. ';
        hyperlink(
            label => $game->player->name,
            url => '/player/'.$game->player->name
        );
        outs ' (' . $game->crga . '), ';
        outs $game->score . ' points, ';

        if (my $url = $game->dumplog_url) {
            hyperlink(
                url    => $url,
                label  => $game->death,
                target => "_blank",
            );
        }
        else {
            outs $game->death;
        }

        if ($game->endtime) {
            outs ' (' . ago(time - $game->endtime, 1) . ')';
        }
    }
}

sub paging {
    my $pager = shift;
    $pager = $pager->pager if $pager->isa('Jifty::Collection');

    my $multipage = $pager->last_page > 1;

    if ($pager->previous_page) {
        hyperlink(
            label => "prev",
            onclick => {
                args => {
                    page => $pager->previous_page,
                }
            }
        );
    }
    elsif ($multipage) {
        outs "prev";
    }

    outs ' / ' if $multipage;

    if ($pager->next_page) {
        hyperlink(
            label => "next",
            onclick => {
                args => {
                    page => $pager->next_page,
                }
            }
        );
    }
    elsif ($multipage) {
        outs "next";
    }
}

template '/salutation' => sub {};

1;

