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

1;

