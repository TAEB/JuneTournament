#!/usr/bin/env perl
package JuneTournament::Model::TrophyChangeCollection;
use strict;
use warnings;
use parent 'JuneTournament::Collection';

sub unshift_order_by {
    my $self = shift;
    return if $self->derived;
    if (@_) {
        my @args = @_;

        unless ( UNIVERSAL::isa( $args[0], 'HASH' ) ) {
            @args = {@args};
        }
        unshift @{ $self->{'order_by'} ||= [] }, @args;
        $self->redo_search();
    }
    return ( $self->{'order_by'} || [] );
}

sub implicit_clauses {
    my $self = shift;

    $self->order_by(column => 'id');
    $self->unshift_order_by(column => 'endtime', order => 'descending');
}

sub limit_to_rank {
    my $self = shift;
    my $rank = shift;
    $self->limit(
        column   => 'rank',
        value    => $rank,
        operator => '<=',
    );
}

sub limit_to_player {
    my $self = shift;
    my $name = shift;
    $name = $name->name if ref $name;

    my $player = $self->join(
        type    => 'left',
        alias1  => 'main',  column1 => 'game',
        table2  => 'games', column2 => 'id',
    );
    $self->limit(
        leftjoin => $player,
        column   => 'player',
        value    => $name,
    );

    return $self;
}

1;

