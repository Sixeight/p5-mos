package Mos;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";



1;
__END__

=encoding utf-8

=head1 NAME

Mos - Simple O/R mapper for my Perl practice.

=head1 SYNOPSIS

    package Service::User;
    use parent "Mos::Service";

    package Model::User;
    use parent "Mos::Model";
    use Mos::Model;

    column("id", "int");
    column("name", "string");
    timestamp;

    package main;

    Service::User->connect("dbi:SQLite:dbname=:memory:");
    Service::User->create({id => 1, name => "bob"});
    Service::User->create({id => 2, name => "alice"});

    my $users = Service::User->all;

    my $user = Service::User->find(1);
    print $user->name;

    my $alice = Service::User->find({name => "alice"});
    print $alice->created_at;

    $alice->name("Mrs. Alice");
    Service::User->update($alice);

=head1 DESCRIPTION

Mos is very simple O/R mapper for my Perl practice.
That means this module is not for production.

Please B<DO NOT USE> on production environment.

=head1 TODO

=over

=item

Transaction

=item

Documentation

=back

=head1 LICENSE

Copyright (C) Tomohiro Nishimura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tomohiro Nishimura E<lt>tomohiro68@gmail.comE<gt>

=cut
