package Mos::Model;

use strict;
use warnings;

use Carp ();
use Mos::Util;

our @EXPORT = qw(mk_attributes mk_time_attributes);

sub import {
  my $class = caller(0);
  {
    no strict "refs";
    for my $name (@EXPORT) {
      *{"$class\::$name"} = \&{$name};
    }

    my $attributes = [];
    my $time_attributes = [];

    *{"$class\::normal_attributes"} = sub { $attributes };
    *{"$class\::time_attributes"}   = sub { $time_attributes };
    *{"$class\::attributes"} = sub {
      my $class = shift;
      [(@{$class->normal_attributes}, @{$class->time_attributes})];
    };
  }
  1;
}

sub new {
  my $class = shift;
  bless {
    (@_ == 1 && ref $_[0] == "HASH") ? %{$_[0]} : @_
  }, $class;
}

sub mk_attributes {
  my @names = @_;
  (@names > 0) or Carp::croak("require names");
  my $class = caller(0);

  {
    no strict "refs";
    *{"$class\::$_"} = _accessor($_) for @names;
  }

  if ($class->can("normal_attributes")) {
    push @{$class->normal_attributes}, @names;
  }
}

sub _accessor {
  my $name = shift;
  sub {
    my ($self, $arg) = @_;
    if (defined $arg) {
      $self->write_attribute($name, $arg);
    } else {
      $self->read_attribute($name);
    }
  }
}

sub mk_time_attributes {
  my @names = @_;
  (@names > 0) or Carp::croak("require names");
  my $class = caller(0);

  {
    no strict "refs";
    for my $name (@names) {
      *{"$class\::$name"} = _time_accessor($name);
      *{"$class\::$name\_str"} = sub {
        my $self = shift;
        "" . ($self->$name || "");
      }
    }

    if ($class->can("time_attributes")) {
      push @{$class->time_attributes}, @names;
    }
  }
}

sub _time_accessor {
  my $name = shift;
  sub {
    my ($self, $arg) = @_;
    if (defined $arg) {
      $self->write_attribute($name, "". $arg);
      return;
    }
    $self->{"_$name"} ||= eval {
      Mos::Util::datetime_from_db($self->read_attribute($name));
    };
  };
}

sub check_attribute ($) {
  my ($self, $key) = @_;
  my @keys = grep { $_ eq $key } @{$self->attributes};
  @keys == 1;
}

sub read_attribute ($) {
  my ($self, $key) = @_;
  $self->check_attribute($key) or Carp::croak("wrong attribute name");
  $self->{$key}
}

sub write_attribute ($$) {
  my ($self, $key, $value) = @_;
  $self->check_attribute($key) or Carp::croak("wrong attribute name");
  $self->{$key} = $value;
}

1;
