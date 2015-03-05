package Mos::Model;

use strict;
use warnings;

use Carp ();
use Mos::Util;

our @EXPORT = qw(column);

our $CONVERT_IN  = "in";
our $CONVERT_OUT = "out";
our $TYPES = {
  int      => sub { no warnings; $_[0] + 0 },
  string   => sub { "" . $_[0] },
  datetime => sub {
    my ($v, $in_out) = @_;
    if ($in_out eq $CONVERT_IN) {
      if ($v->isa("DateTime")) {
        $v = Mos::Util::time_string_from_datetime($v);
      }
    } else {
      $v = Mos::Util::datetime_from_time_string($v);
    }
    $v;
  },
};

sub import {
  my $class = caller(0);
  {
    no strict "refs";
    for my $name (@EXPORT) {
      *{"$class\::$name"} = \&{$name};
    }

    my $attribute_map = {};
    *{"$class\::attribute_map"} = sub { $attribute_map };
  }
  1;
}

sub new {
  my $class = shift;
  bless {
    (@_ == 1 && ref $_[0] eq "HASH") ? %{$_[0]} : @_
  }, $class;
}

sub column ($$) {
  my ($name, $type) = @_;
  my $class = caller(0);

  {
    no strict "refs";
    *{"$class\::$name"} = _attribute($name, $type);
  }

  $class->attribute_map->{$name} = $type;
}

sub _attribute ($$) {
  my ($name, $type) = @_;
  sub {
    my ($self, $value) = @_;
    if (defined $value) {
      my $v = $TYPES->{$type}->($value, $CONVERT_IN);
      $self->write_attribute($name, $v);
    } else {
      my $v = $self->read_attribute($name);
      $TYPES->{$type}->($v, $CONVERT_OUT);
    }
  };
}

sub check_attribute ($) {
  my ($self, $key) = @_;
  $self->attribute_map->{$key};
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
