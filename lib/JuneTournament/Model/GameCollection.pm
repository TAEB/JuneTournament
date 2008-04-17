#!/usr/bin/env perl
package JuneTournament::Model::GameCollection;
use strict;
use warnings;
use parent 'JuneTournament::Collection';

sub limit_to_ascensions {
    my $self = shift;
    $self->limit(column => 'ascended', value => 1);
    return $self;
}

sub binary_search {
    my $self = shift;
    my $sub  = shift;

    my $lo = 1;
    my $hi = $self->count;

    while ($lo < $hi) {
        my $i = ($hi + $lo) >> 1;
        $self->set_page_info(
            per_page     => 1,
            current_page => $i,
        );
        local ($_) = <$self>;

        my $cmp = $sub->();

        # if they're equal, then our rank should be higher, because earlier is
        # better
        if ($cmp >= 0) { $lo = $i + 1 }
                  else { $hi = $i - 1 }
    }

    return $hi;
}

1;

