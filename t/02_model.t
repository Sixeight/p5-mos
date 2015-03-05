use strict;
use Test::More 0.98;

package Model::Test;

use parent "Mos::Model";
use Mos::Model;

package main;

subtest "DSL" => sub {
  ok(Model::Test->can("column"), "has column");
  ok(Model::Test->can("timestamp"), "has timestamp");
  ok(Model::Test->can("attribute_map"), "has attribute_map");
  ok(Model::Test->can("attributes"), "has attributes");
  ok(Model::Test->can("normal_attributes"), "has normal_attributes");
  ok(Model::Test->can("time_attributes"), "has time_attributes");
};

package Model::Person;

use parent "Mos::Model";
use Mos::Model;

column("id", "int");
column("name", "string");
column("age", "int");
column("borned_at", "datetime");

timestamp;

package main;

subtest "attribute_map" => sub {
  my $attribute_map = {
    id => "int", name => "string", age => "int", borned_at => "datetime",
    created_at => "datetime", updated_at => "datetime",
  };
  is_deeply(Model::Person->attribute_map, $attribute_map, "attribute_map is correct");
};

subtest "attributes" => sub {
  my $attributes = [ qw( age borned_at created_at id name updated_at ) ];
  is_deeply(Model::Person->attributes, $attributes, "attributes is correct");
};

subtest "normal attributes" => sub {
  my $attributes = [ qw( age id name ) ];
  is_deeply(Model::Person->normal_attributes, $attributes, "normal_attributes is correct");
};

subtest "time attributes" => sub {
  my $attributes = [ qw( borned_at created_at updated_at ) ];
  is_deeply(Model::Person->time_attributes, $attributes, "time_attributes is correct");
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
  is($person->{borned_at}, "2015-03-04 16:23:13", "raw borned_at_str is '2015-03-04 16:23:13' as string");

  $expect->set(year => 2016, month => 4, day => 5, hour => 17, minute => 24, second => 14);
  is($person->created_at, $expect, "created_at is '2016-04-05 17::24:14' as DateTime");
  isa_ok($person->created_at, "DateTime", "created_at isa DateTime");
  is($person->{created_at}, "2016-04-05 17:24:14", "raw created_at is '2016-04-05 17:24:14' as string");

  $expect->set(year => 2017, month => 5, day => 6, hour => 18, minute => 25, second => 15);
  is($person->updated_at, $expect, "updated_at is '2017-05-06 18:25:15' as DateTime");
  isa_ok($person->updated_at, "DateTime", "updated_at isa DateTime");
  is($person->{updated_at}, "2017-05-06 18:25:15", "raw updated_at is '2017-05-06 18:25:15' as string");
}

subtest "get as time attribute" => sub {
  my $values = {
    borned_at  => "2015-03-04 16:23:13",
    created_at => "2016-04-05 17:24:14",
    updated_at => "2017-05-06 18:25:15",
  };
  my $person = Model::Person->new($values);
  test_time_attribute($person);
};

subtest "set as time attribute" => sub {
  my $person = Model::Person->new;
  $person->borned_at("2015-03-04 16:23:13");
  $person->created_at("2016-04-05 17:24:14");
  $person->updated_at("2017-05-06 18:25:15");
  test_time_attribute($person);
};

subtest "convert value with type" => sub {
  my $person = Model::Person->new;
  $person->id("5");
  is($person->id, 5, qq("5" has converted to 5));
  $person->id("a");
  is($person->id, 0, qq("a" has converted to 0));
  $person->name(10);
  is($person->name, "10", qq(10 has converted to "10"));
  my $time = DateTime->new(year => 2015, month => 3, day => 4, hour => 16, minute => 23, second => 13);
  $person->borned_at("2015-03-04 16:23:13");
  is($person->borned_at, $time, "string has converted datetime");
  $person->borned_at($time);
  is($person->read_attribute("borned_at"), "2015-03-04 16:23:13", "datetime has conveted string")
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
