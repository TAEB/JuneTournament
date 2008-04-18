#!/usr/bin/env perl
package JuneTournament::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

on '/player/*' => run {
    set name => $1;
    show '/player';
};

on '/trophy/*' => run {
    set name => $1;
    show '/trophy';
};

1;

