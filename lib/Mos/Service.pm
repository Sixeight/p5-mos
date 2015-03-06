package Mos::Service;

use strict;
use warnings;
use utf8;

use DBIx::Sunny;
use SQL::Maker;
use Carp ();
use Class::Load ();

use Mos::Util;

our $UPDATE_ATTRIBUTE_NAME = "updated_at";

my $dbh;
my $query_builder;

sub dbh {
  my ($class, $arg) = @_;
  if (defined $arg) {
    $dbh = $arg;
  }
  $dbh;
}

sub query_builder {
  my $class = shift;
  $query_builder ||= SQL::Maker->new(driver => "mysql");
}

sub table_name {
  my $class = shift;
  my @_parts = split "::", $class;
  lc($_parts[-1]) . "s";
}

sub model_name {
  my $class = shift;
  my @_parts = split "::", $class;
  my $name = pop @_parts;
  pop @_parts;
  my $model_name = join "::", @_parts, "Model", $name;
  Class::Load::load_class($model_name);
  $model_name;
}

sub connect {
  my $class = shift;
  my ($dsn, $user, $pass, $attr) = @_;
  (defined $dsn) or Carp::croak("need dsn");
  if (!defined $attr || ref $attr ne "HASH") {
    $attr = {};
  }
  if ($class->is_connected) {
    return $class->dbh;
  }
  my $_dbh = DBIx::Sunny->connect(
    $dsn, $user, $pass, $attr);
  $class->dbh($_dbh);
}

sub disconnect {
  my $class = shift;
  $class->dbh->disconnect;
  $dbh = undef;
}

sub is_connected {
  my $class = shift;
  defined $class->dbh;
}

sub transaction {
  my ($class, $block) = @_;
  my $ac = $class->dbh->{AutoCommit};
  my $re = $class->dbh->{RaiseError};
  $class->dbh->{AutoCommit} = 0;
  $class->dbh->{RaiseError} = 1;
  eval {
    $block->($class);
    $class->dbh->commit;
  };
  if ($@) {
    $class->dbh->rollback;
  }
  $class->dbh->{RaiseError} = $re;
  $class->dbh->{AutoCommit} = $ac;
}

sub all {
  my ($class, $opts) = @_;
  if (!defined $opts || ref $opts ne "HASH") {
    $opts = +{};
  }
  if (!$class->is_connected) {
    $class->connect;
  }
  my $model_name = $class->model_name;
  my $table_name = $class->table_name;
  my ($query, @binds) = $class->query_builder->select($table_name, ["*"], +{}, $opts);
  my $rows = $class->dbh->select_all($query, @binds);
  [map { $model_name->new($_) } @$rows];
}

sub all_by_ids {
  my ($class, $user_ids, $opts) = @_;
  if (ref $user_ids ne "ARRAY") {
    return [];
  }
  if (!defined $opts || ref $opts ne "HASH") {
    $opts = {};
  }
  my $table_name = $class->table_name;
  my $where = {id => $user_ids};
  my ($query, @binds) = $class->query_builder->select($table_name, ["*"], $where, $opts);
  my $rows = $class->dbh->select_all($query, @binds);
  my $model_name = $class->model_name;
  [map { $model_name->new($_) } @$rows];
}

sub find {
  my ($class, $where, $opts) = @_;
  if (!defined $opts) {
    $opts = +{};
  }
  if (!$class->is_connected) {
    $class->connect;
  }
  if (ref $where ne "HASH") {
    $where = {id => $where}
  }
  my $model_name = $class->model_name;
  my $table_name = $class->table_name;
  $where = +{
    map  { $_ => $where->{$_} }
    grep { $where->{$_} }
    @{$model_name->attributes}
  };
  my ($query, @binds) = $class->query_builder->select($table_name, ["*"], $where, $opts);
  my $ret = $class->dbh->select_row($query, @binds);
  $ret ? $model_name->new($ret) : undef;
}

sub create {
  my ($class, $values, $opts) = @_;
  if (!$class->is_connected) {
    $class->connect;
  }
  (ref $values eq "HASH") or Carp::croak("require hash ref");
  if (!defined $opts || ref $opts ne "HASH") {
    $opts = +{};
  }
  my $model_name = $class->model_name;
  $values = {
    map  { $_ => $values->{$_} }
    grep { defined $values->{$_} }
    @{$model_name->attributes}
  };
  for my $time_attribute (@{$model_name->time_attributes}) {
    $values->{$time_attribute} ||= Mos::Util->now;
  }
  my $table_name = $class->table_name;
  my ($query, @binds) = $class->query_builder->insert($table_name, $values, $opts);
  $class->dbh->query($query, @binds);
}

sub update {
  my ($class, $model) = @_;
  if (!$class->is_connected) {
    $class->connect;
  }
  my $model_name = $class->model_name;
  ($model->isa($model_name)) or Carp::croak("invalid model: $model, require $model_name");
  my $set = {
    map  { $_ => $model->{$_} }
    grep { $_ ne "id" }
    @{$model_name->attributes}
  };
  for my $time_attribute (@{$model_name->time_attributes}) {
    if ($time_attribute ne $UPDATE_ATTRIBUTE_NAME) {
      next;
    }
    $set->{$time_attribute} = Mos::Util->now;
  }
  my $table_name = $class->table_name;
  my $where = +{id => $model->id};
  my ($query, @binds) = $class->query_builder->update($table_name, $set, $where);
  $class->dbh->query($query, @binds);
}

1;
