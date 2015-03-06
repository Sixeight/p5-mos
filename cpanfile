requires 'perl', '5.008001';

requires "Carp";
requires "Class::Load";
requires "DBIx::Sunny";
requires "SQL::Maker";
requires "SQL::NamedPlaceholder";
requires "DateTime";
requires "DateTime::Format::MySQL";

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires "DBD::SQLite";
};
