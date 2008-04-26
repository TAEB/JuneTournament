#!/usr/bin/env perl
package JuneTournament::Action::CreateUser;
use strict;
use warnings;
use parent 'Jifty::Action::Record::Create';

sub record_class { 'JuneTournament::Model::User' }

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'name' =>
        type is 'text',
        ajax validates;
    param 'token' =>
        render as 'hidden';
};

sub validate_name {
    my $self = shift;
    my $name = shift;

    my $user = JuneTournament::Model::User->new(current_user => JuneTournament::CurrentUser->superuser);

    return $self->validation_error(name => "That doesn't look like a valid name.")
        unless $user->validate_name($name)

    $user->load_by_cols(name => $name);

    return $self->validation_error(name => "We already have a user with that name.")
        if $user->id;

    return $self->validation_ok('name');
}

sub take_action {
    my $self = shift;

    my $name  = $self->argument_value('name');
    my $token = $self->argument_value('token');

    # Users don't have a 'token' column
    $self->argument_value(token => undef);

    my $has_token = JuneTournament::Model::User->verify_token($token => $name);
    if ($has_token) {
        $self->result->message("Account created!");
        return 1;
    }

    if (!defined($has_token)) {
        $self->result->error("I can't find your rcfile. Are you sure you spelled your username correctly?");
    }
    else
        $self->result->error("I can't find '$token' in your rcfile.");
    }

    return 0;
}

1;

