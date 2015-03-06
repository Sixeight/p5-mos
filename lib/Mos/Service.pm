package Mos::Service;

use strict;
use warnings;
use utf8;

use DBIx::Sunny;
use SQL::Maker;
use SQL::NamedPlaceholder ();
use Carp ();
use Class::Load ();

use Mos::Util;

our $UPDATE_ATTRIBUTE_NAME = "updated_at";

my $dbh;
my $in_transaction = 0;
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

sub connect_if_needed {
  my $class = shift;
  unless ($class->is_connected) {
    $class->connect;
  }
}

sub transaction {
  my ($class, $block) = @_;
  if ($in_transaction) {
    $block->($class);
    return;
  }
  my $ac = $class->dbh->{AutoCommit};
  my $re = $class->dbh->{RaiseError};
  $class->dbh->{AutoCommit} = 0;
  $class->dbh->{RaiseError} = 1;
  eval {
    $in_transaction = 1;
    $block->($class);
    $in_transaction = 0;
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
  $class->connect_if_needed or Carp::croak("failed to connect database");
  if (!defined $opts || ref $opts ne "HASH") {
    $opts = +{};
  }
  my $model_name = $class->model_name;
  my $table_name = $class->table_name;
  my ($query, @binds) = $class->query_builder->select($table_name, ["*"], +{}, $opts);
  my $rows = $class->dbh->select_all($query, @binds);
  [map { $model_name->new($_) } @$rows];
}

sub all_by_ids {
  my ($class, $user_ids, $opts) = @_;
  return [] if ref $user_ids ne "ARRAY";
  $class->connect_if_needed or Carp::croak("failed to connect database");
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
  $class->connect_if_needed or Carp::croak("failed to connect database");
  if (!defined $opts) {
    $opts = +{};
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
  $class->connect_if_needed or Carp::croak("failed to connect database");
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
  $class->query($query, @binds);
}

sub update {
  my ($class, $model) = @_;
  $class->connect_if_needed or Carp::croak("failed to connect database");
  my $model_name = $class->model_name;
  (ref $model && $model->isa($model_name))
    or Carp::croak("invalid model: $model, require $model_name");
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
  $class->query($query, @binds);
}

sub destroy {
  my ($class, $model, $opts) = @_;
  $class->connect_if_needed or Carp::croak("failed to connect database");
  my $model_name = $class->model_name;
  (ref $model && $model->isa($model_name))
    or Carp::croak("invalid model: $model, require $model_name");
  if (!defined $opts || ref $opts ne "HASH") {
    $opts = {};
  }
  $class->delete({id => $model->id}, $opts);
}

sub delete {
  my ($class, $where, $opts) = @_;
  $class->connect_if_needed or Carp::croak("failed to connect database");
  (ref $where eq "HASH") or Carp::croak("need hash ref");
  if (!defined $opts || ref $opts ne "HASH") {
    $opts = {};
  }
  my $table_name = $class->table_name;
  my ($query, @binds) = $class->query_builder->delete($table_name, $where, $opts);
  $class->query($query, @binds);
}

sub query {
  my $class = shift;
  $class->connect_if_needed or Carp::croak("failed to connect database");
  $class->dbh->query(_expand_query(@_));
}

sub _expand_query {
  my $query = shift;
  my @binds = @_;

  if (@_ == 1 && ref $_[0] eq "HASH") {
    ($query, my $binds) = SQL::NamedPlaceholder::bind_named($query, $_[0]);
    @binds = @$binds;
  }

  ($query, @binds);
}

1;
