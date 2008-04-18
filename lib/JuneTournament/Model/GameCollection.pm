#!/usr/bin/env perl
package JuneTournament::Model::GameCollection;
use strict;
use warnings;
use parent 'JuneTournament::Collection';
use Scalar::Util 'blessed';

sub implicit_clauses {
    my $self = shift;

    $self->order_by(column => 'id');
    $self->add_order_by(column => 'endtime');
}

sub ascensions {
    my $class = shift;
    return $class->limit_to_ascensions if blessed $class;
    my $ascs = $class->new;
    $ascs->unlimit;
    $ascs->limit_to_ascensions;
    return $ascs;
}

sub limit_to_ascensions {
    my $self = shift;
    $self->limit(column => 'ascended', value => 1);
    return $self;
}

1;

