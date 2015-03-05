package Mos::Model;

use strict;
use warnings;

use Carp ();
use Class::Accessor::Lite new => 1;

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

sub mk_attributes {
  my @names = @_;
  (@names > 0) or Carp::croak("require names");
  my $class = caller(0);

  Class::Accessor::Lite::_mk_accessors($class, @names);

  if ($class->can("normal_attributes")) {
    push @{$class->normal_attributes}, @names;
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
      $self->{$name} = "". $arg;
      return;
    }
    $self->{"_$name"} ||= eval {
      Mos::Util::datetime_from_db($self->{$name});
    };
  };
}

1;
