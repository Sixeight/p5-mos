use strict;
use Test::More 0.98;

package Model::Test;

use parent "Mos::Model";
use Mos::Model;

package main;

subtest "DSL" => sub {
  ok(Model::Test->can("mk_attributes"),      "has mk_attributes");
  ok(Model::Test->can("mk_time_attributes"), "has mk_time_attributes");
  ok(Model::Test->can("normal_attributes"),  "has normal_attributes");
  ok(Model::Test->can("time_attributes"),     "has time_attributes");
  ok(Model::Test->can("attributes"),         "has attributes");
};

package Model::Person;

use parent "Mos::Model";
use Mos::Model;

mk_attributes(qw(id name age));
mk_time_attributes(qw(borned_at));

package main;

subtest "normal attributes" => sub {
  my $attributes = [qw( id name age)];
  is_deeply(Model::Person->normal_attributes, $attributes, "normal attributes are id name age");
};

subtest "time attributes" => sub {
  my $attributes = [qw( borned_at )];
  is_deeply(Model::Person->time_attributes, $attributes, "time attributes are boarned_at");
};

subtest "time attributes" => sub {
  my $attributes = [qw( id name age borned_at )];
  is_deeply(Model::Person->attributes, $attributes, "time attributes are id name age boarned_at");
};

sub test_normal_attribute {
  my $person = shift;
  is($person->id, 1, "id is 1");
  is($person->name, "test", "name is test");
  is($person->age, 28, "age is 28");
  is($person->{id}, 1, "raw id is 1");
  is($person->{name}, "test", "raw name is test");
  is($person->{age}, 28, "raw age is 28");
}

subtest "get as normal attribute" => sub {
  my $person = Model::Person->new({id => 1, name => "test", age => 28});
  test_normal_attribute($person);
};

subtest "set as normal attribute" => sub {
  my $person = Model::Person->new;
  $person->id(1);
  $person->name("test");
  $person->age(28);
  test_normal_attribute($person);
};

sub test_time_attribute {
  my $person = shift;
  my $expect = DateTime->new(year => 2015, month => 3, day => 4, hour => 16, minute => 23, second => 13);
  is($person->borned_at, $expect, "borned_at is '2015-03-04 16:23:13' as DateTime");
  isa_ok($person->borned_at, "DateTime", "borned_at isa DateTime");
  is($person->borned_at_str, "2015-03-04 16:23:13", "borned_at_str is '2015-03-04 16:23:13' as string");
  is($person->{borned_at}, "2015-03-04 16:23:13", "raw borned_at_str is '2015-03-04 16:23:13' as string");
}

subtest "get as time attribute" => sub {
  my $person = Model::Person->new({borned_at => "2015-03-04 16:23:13"});
  test_time_attribute($person);
};

subtest "set as time attribute" => sub {
  my $person = Model::Person->new;
  $person->borned_at("2015-03-04 16:23:13");
  test_time_attribute($person);
};

subtest "read_attribute" => sub {
  my $person = Model::Person->new({name => "test"});
  is($person->read_attribute("name"), "test", "certain attribute name");
  is($person->read_attribute("id"), undef, "certain attribute name but undef");
  eval { $person->read_attribute("wrong") };
  like($@, qr/wrong attribute name/, "wrong attribute name");
};

subtest "write_attribute" => sub {
  my $person = Model::Person->new({name => "test"});
  $person->write_attribute("id", 1);
  is($person->id, 1, "new attribute value");
  $person->write_attribute("name", "name");
  is($person->name, "name", "update attribute value");
  eval { $person->write_attribute("tiger", "cat") };
  like($@, qr/wrong attribute name/, "wrong attribute name");
};

done_testing;
