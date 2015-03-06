use strict;
use Test::More 0.98;

package Service::A;
use parent "Mos::Service";

package Service::B;
use parent "Mos::Service";

package Model::A;
use parent "Mos::Model";
use Mos::Model;

column("id", "int");

package Model::B;
use parent "Mos::Model";
use Mos::Model;

column("id", "int");

package main;

eval { Service::A->find(1) };
like($@, qr/need dsn/, "need connect");

Mos::Service->connect("dbi:SQLite:dbname=:memory:");
Mos::Service->dbh->do("CREATE TABLE IF NOT EXISTS 'as' (id INTEGER PRIMARY KEY)");
Mos::Service->dbh->do("CREATE TABLE IF NOT EXISTS 'bs' (id INTEGER PRIMARY KEY)");

subtest "with A" => sub {
  Service::A->create({id => 1});
  Service::A->create({id => 2});
  my $as = Service::A->all;
  is(@$as, 2, "create two items");
  my $a = Service::A->find(1);
  ok(defined $a, "can fetch");
};

subtest "with B" => sub {
  Service::B->create({id => 1});
  Service::B->create({id => 2});
  my $bs = Service::B->all;
  is(@$bs, 2, "create two items");
  my $b = Service::B->find(1);
  ok(defined $b, "can fetch");
};

sub insert_a_with_transaction {
  Service::A->transaction(sub {
    $_[0]->create({id => 5});
  });
}

sub insert_b_with_transaction {
  Service::B->transaction(sub {
    $_[0]->create({id => 5});
  });
}

subtest "nested transaction (success)" => sub {
  Mos::Service->transaction(sub {
    insert_a_with_transaction;
    insert_b_with_transaction;
  });
  my $a = Service::A->find(5);
  ok(defined $a, "created a");
  my $b = Service::B->find(5);
  ok(defined $b, "created b");

  Mos::Service->dbh->do("DELETE FROM 'as'");
  Mos::Service->dbh->do("DELETE FROM 'bs'");
};

subtest "nested transaction (fail)" => sub {
  Mos::Service->transaction(sub {
    insert_a_with_transaction;
    insert_b_with_transaction;
    Mos::Service->create({id => 2}) # invalid service
  });
  my $a = Service::A->find(5);
  ok(!defined $a, "not created a");
  my $b = Service::B->find(5);
  ok(!defined $b, "not created b");
};

done_testing;
