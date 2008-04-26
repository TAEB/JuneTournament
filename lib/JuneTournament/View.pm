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
    };

    render_region(
        path => '/region/trophies_summary',
        name => 'trophies_summary',
    );

    h3 { "Trophy Changes" };
    render_region(
        path => '/region/trophy_changes',
        name => 'trophy_changes',
    );

    h3 { "Recent Ascensions" };
    render_region(
        path => '/region/recent_ascensions',
        name => 'recent_ascensions',
    );

    h3 { "Recent Games" };
    render_region(
        path => '/region/recent_games',
        name => 'recent_games',
    );
};

template '/player' => page {
    my $name = get('name') || redirect('/__jifty/error/404');
    my $player = JuneTournament->player($name) || redirect('/__jifty/error/404');
    $name = $player->name;

    h1 { $name };

    if ($player->trophy_changes->count) {
        h3 { "Trophy Changes" };
        render_region(
            path => '/region/player_trophy_changes',
            name => 'player_trophy_changes',
            arguments => {
                name => $name,
            },
        );
    }

    if ($player->ascensions->count) {
        h3 { "Recent Ascensions" };
        render_region(
            path => '/region/player_ascs',
            name => 'player_ascs',
            arguments => {
                name => $name,
            },
        );
    }

    h3 { "Recent Games" };
    render_region(
        path => '/region/player_games',
        name => 'player_games',
        arguments => {
            name => $name,
        },
    );
};

template '/trophy' => page {
    my $name = get('name') || redirect('/__jifty/error/404');
    h1 { $name };

    h3 { "Standings" };
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

template '/region/recent_games' => sub {
    games();
};

template '/region/player_ascs' => sub {
    games(ascended => 1, player => get('name'));
};

template '/region/player_games' => sub {
    games(player => get('name'));
};

template '/region/scums' => sub {
    games(
        [column => 'score', value => '1000', operator => '<'],
        death => 'quit',
        death => 'escaped',
    );
};

template '/region/trophy' => sub {
    my $name = get('name') || redirect('/__jifty/error/404');
    my @args = (
        trophy => $name,
    );

    div {
        if (get 'inline') {
            attr { class is 'boxed' };
            h4 { trophy($name) }
            push @args, per_page => 5;
        }

        games(@args);
    }
};

template '/region/trophies_summary' => sub {
    h3 { "Trophies" };
    ol {
        for my $trophy (JuneTournament->trophies) {
            li {
                render_region(
                    path => '/region/trophy_summary',
                    name => "${trophy}_summary",
                    arguments => {
                        name => $trophy,
                    },
                );

            }
        }
    }
};

template '/region/trophy_summary' => sub {
    my $trophy = get('name') || redirect('/__jifty/error/404');

    hyperlink(
        label => $trophy,
        onclick => {
            replace_with => '/region/trophy',
            arguments => {
                name   => $trophy,
                inline => 1,
            }
        },
    );

    my $class = "JuneTournament::Trophy::$trophy";
    my $standings = $class->standings;
    my $game = $standings->first;

    outs " (";
    if ($game) {
        outs "current winner: ";
        outs player($game->player);

        if ($class->can('extra_display')) {
            outs " with " . $class->extra_display($game);
        }
    }
    else {
        outs "No winner yet! Get cracking!";
    }
    outs ")";
};

my @ranks = qw(zeroth? first second third 4th 5th);

template '/region/trophy_changes' => sub {
    my $page = (get 'page') || 1;

    my $changes = JuneTournament::Model::TrophyChangeCollection->new;
    $changes->limit_to_rank(5);
    changes($changes, page => $page);
};

template '/region/player_trophy_changes' => sub {
    my $page = (get 'page') || 1;
    my $name = (get 'name') || redirect('/__jifty/error/404');

    my $player = JuneTournament::Model::Player->new;
    $player->load_by_cols(name => $name);
    $player->id || redirect('/__jifty/error/404');

    my $changes = $player->trophy_changes;
    $changes->limit_to_rank(5);
    changes($changes, page => $page);
};

sub changes {
    my $changes = shift;
    my %args    = (
        page     => 1,
        per_page => 5,
        @_,
    );

    $changes->set_page_info(
        current_page => $args{page},
        per_page => $args{per_page},
    );

    ul {
        for my $change (@$changes) {
            li {
                change($change);
            }
        }
    };

    paging($changes);
}

sub change {
    my $change = shift;
    my $trophy_class = "JuneTournament::Trophy::" . $change->trophy;
    my $rank = $change->rank;
    my $game = $change->game;

    outs player($game->player);
    outs " wins ";

    if ($rank == 1) {
        strong { "first" }
    }
    else {
        outs $ranks[$rank];
    }

    outs " for ";
    trophy($change->trophy);
    outs " with ";

    hyperlink(
        label  => $trophy_class->extra_display($game),
        url    => $game->dumplog_url,
        target => "_blank",
    );

    outs " (" . ago(time - $change->endtime, 1) . ")";
}

sub games {
    my $games;
    my $extra_display;
    my $position_is_important = 0;
    my $per_page = 10;

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
                    $class->can('find_rank') || redirect('/__jifty/error/404');
                    $games = $class->standings;
                    $extra_display = sub { $class->extra_display(shift) }
                        if $class->can('extra_display');
                    $position_is_important = 1;
                }
                elsif ($column eq 'per_page') {
                    $per_page = $value;
                }
                else {
                    $games->limit(column => $column, value => $value);
                }
            }
        }
    }

    $games->order_by(column => 'id', order => 'desc')
        unless $position_is_important;

    my $page = (get 'page') || 1;
    $games->set_page_info(per_page => $per_page, current_page => $page);
    my $id = $games->pager->first;

    div {
        ul {
            for (@$games) {
                li {
                    outs game($_, $position_is_important ? $id++ : undef);
                    outs ' - ' . $extra_display->($_) if $extra_display;
                }
            }
        };
        paging($games);
    }
}

sub player {
    my $player = shift;
    hyperlink(
        label => $player->name,
        url   => '/player/' . $player->name,
    );
}

sub game {
    my $game = shift;
    my $id = defined($_[0]) ? shift : $game->id;

    span {
        outs $id . '. ';
        outs player($game->player);
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

sub trophy {
    my $name = shift;
    hyperlink(
        label => $name,
        url => "/trophy/$name",
    );
}

template '/salutation' => sub {};

1;

