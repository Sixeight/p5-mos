use strict;
use Test::More 0.98;

package Service;

use parent "Mos::Service";

my $dsn = "dbi:SQLite:dbname=:memory:";
my $user = "";
my $pass = "";

sub connect {
  my $self = shift;
  $self->SUPER::connect($dsn, $user, $pass);
}

package Service::User;

use parent -norequire, "Service";

package Model::User;

use parent "Mos::Model";
use Mos::Model;

column("id", "int");
column("name", "string");

package main;

subtest "connect" => sub {
  Service->connect;
  ok(Service->is_connected, "connected");
  Service->disconnect;
  ok(!Service->is_connected, "disconnect");
};

subtest "connect without dsn" => sub {
  eval { Mos::Service->connect };
  like($@, qr/need dsn/, "need dsn");
};

Service::User->connect;

Service::User->dbh->query(<<EOS
  CREATE TABLE IF NOT EXISTS users (
    `id`   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `name` VARCHAR(32) NOT NULL
  );
EOS
);

for (my $i = 1; $i <= 5; $i++) {
  Service::User->dbh->query("INSERT INTO users (id, name) VALUES (?, ?)", $i, "test-$i");
}

END {
  Service::User->dbh->query("DROP table users");
  Service::User->disconnect;
}

subtest "table_name" => sub {
  is(Service::User->table_name, "users", "table_name is users");
};

subtest "model name" => sub {
  is(Service::User->model_name, "Model::User", "model_name is Model::User");
};

subtest "query_builder" => sub {
  isa_ok(Service::User->query_builder, "SQL::Maker");
};

subtest "all without options" => sub {
  my $users = Service::User->all;
  ok(@$users == 5, "fetch all users");
};

subtest "all with option" => sub {
  my $limit = 3;
  my $users = Service::User->all({limit => $limit});
  ok(@$users == 3, "fetch limited users");
};

subtest "all with order" => sub {
  my $users = Service::User->all({order_by => "id DESC"});
  is($users->[0]->id, 5, "DESC order");
};

subtest "find with id" => sub {
  my $user = Service::User->find(1);
  is($user->id, 1, "user id is 1");
  is($user->name, "test-1", "user name is test-1");
};

subtest "find with query" => sub {
  my $user = Service::User->find({name => "test-2"});
  is($user->id, 2, "user id is 2");
  is($user->name, "test-2", "user name is test-2");
};

subtest "all_by_ids" => sub {
  my $users = Service::User->all_by_ids;
  is_deeply($users, [], "returns [] when without ids");
  $users = Service::User->all_by_ids([]);
  is_deeply($users, [], "returns [] when with empty array");
  $users = Service::User->all_by_ids([1, 3, 5]);
  is($users->[0]->id, 1, "id 1 is fetched");
  is($users->[1]->id, 3, "id 3 is fetched");
  is($users->[2]->id, 5, "id 5 is fetched");
};

subtest "create new user" => sub {
  my $parameters = {id => 100, name => "test-name"};
  my $ret = Service::User->create($parameters);
  ok($ret, "create success");
  my $user = Service::User->find(100);
  is($user->name, $parameters->{name}, "user name is test-name");
};

subtest "update user" => sub {
  my $user = Service::User->find(1);
  $user->name("updated");
  my $ret = Service::User->update($user);
  ok($ret, "update success");
  $user = Service::User->find(1);
  is($user->name, "updated", "user name is updated");
};

subtest "destroy" => sub {
  Service::User->create({id => 345, name => "will delete"});
  my $user = Service::User->find(345);
  ok(defined $user, "there is a user before destroy");
  Service::User->destroy($user);
  $user = Service::User->find(345);
  ok(!defined $user, "there is no user after destroy")
};

subtest "delete" => sub {
  Service::User->create({id => 789, name => "mr. delete"});
  my $user = Service::User->find(789);
  ok(defined $user, "there is a user before destroy");
  Service::User->delete({id => 789});
  $user = Service::User->find(789);
  ok(!defined $user, "there is no user after destroy")
};

subtest "query" => sub {
  Service::User->query("INSERT INTO users (id, name) VALUES (?, ?)", 123, "query1");
  my $user = Service::User->find(123);
  is($user->name, "query1", "query with placeholder");
};

subtest "query with named placeholder" => sub {
  my $query = "INSERT INTO users (id, name) VALUES (:id, :name)";
  Service::User->query($query, {id => 135, name => "panda"});
  my $user = Service::User->find(135);
  is($user->name, "panda", "query with named placeholder");
};

subtest "transaction" => sub {
  my $ac = Service::User->dbh->{AutoCommit};
  my $re = Service::User->dbh->{RaiseError};
  Service::User->transaction(sub {
    ok(!Service::User->dbh->{AutoCommit}, "inner transaction block auto commit off");
    ok( Service::User->dbh->{RaiseError}, "inner transaction block raise error on");
    my $service = shift;
    $service->create({id => 20, name => "cat"});
    $service->create({id => 30, name => "dog"});
  });
  is(Service::User->dbh->{AutoCommit}, $ac, "outer transaction block auto commit status is back");
  is(Service::User->dbh->{RaiseError}, $re, "outer transaction block raise error status is back");
  my $user = Service::User->find(20);
  is($user->name, "cat", "transaction has been commited");
};

subtest "transaction(rollback)" => sub {
  Service::User->transaction(sub {
    my $service = shift;
    $service->create({id => 200, name => "cat"});
    $service->create({id => 300, nmae => "dog"}); # typo!
  });
  my $user = Service::User->find(200);
  is($user, undef, "roll backed");
};

sub with_transaction {
  Service::User->transaction(sub {
    my $s = shift;
    $s->create({id => 1000, name => "cake"});
  });
}

subtest "nested transaction" => sub {
  Service::User->transaction(sub {
    my $s = shift;
    $s->create({id => 1500, name => "banana"});
    with_transaction();
  });
  my $user = Service::User->find(1000);
  is($user->name, "cake", "transaction has been commited");
};

done_testing;
