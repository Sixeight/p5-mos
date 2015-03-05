[![Build Status](https://travis-ci.org/Sixeight/p5-mos.svg?branch=master)](https://travis-ci.org/Sixeight/p5-mos)
# NAME

Mos - Simple O/R mapper for my Perl practice.

# SYNOPSIS

    package Service::User;
    use parent "Mos::Service";

    package Model::User;
    use parent "Mos::Model";
    use Mos::Model;

    column("id", "int");
    column("name", "string");
    timestamp;

    package main;

    Service::User->connect("dbi:SQLite:dbname=:memory");
    Service::User->create({id => 1, name => "bob"});
    Service::User->create({id => 2, name => "alice"});

    my $users = Service::User->all;

    my $user = Service::User->find(1);
    print $user->name;

    my $alice = Service::User->find({name => "alice"});
    print $alice->created_at;

    $alice->name("Mrs. Alice");
    Service::User->update($alice);

# DESCRIPTION

Mos is very simple O/R mapper for my Perl practice.
That means this module is not for production.

Please **DO NOT USE** on production environment.

# TODO

- Transaction
- Documentation

# LICENSE

Copyright (C) Tomohiro Nishimura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tomohiro Nishimura <tomohiro68@gmail.com>
