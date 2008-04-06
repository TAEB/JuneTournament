#!/usr/bin/env perl
package JuneTournament::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

on '/player/*' => run {
    my $name = $1;
    set name => $1;
    show '/player';
};

1;

