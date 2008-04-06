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

1;

