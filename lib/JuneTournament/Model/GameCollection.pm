#!/usr/bin/env perl
package JuneTournament::Model::GameCollection;
use strict;
use warnings;
use parent 'JuneTournament::Collection';
use Scalar::Util 'blessed';

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
    $self->unshift_order_by(column => 'endtime');
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

