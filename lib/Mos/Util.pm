package Mos::Util;

use strict;
use warnings;

use DateTime;
use DateTime::Format::MySQL;

our $TIME_ZONE = "UTC";

sub now () {
    my $now = DateTime->now(time_zone => $Mos::Util::TIME_ZONE);
    $now->set_formatter( DateTime::Format::MySQL->new );
    $now;
}

sub time_string_from_datetime ($) {
    my $dt = shift;
    $dt->set_time_zone($Mos::Util::TIME_ZONE);
    $dt->set_formatter(DateTime::Format::MySQL->new);
    "" . $dt;
}

sub datetime_from_time_string ($) {
    my $ts = shift;
    my $dt = DateTime::Format::MySQL->parse_datetime($ts);
    $dt->set_time_zone($Mos::Util::TIME_ZONE);
    $dt->set_formatter(DateTime::Format::MySQL->new);
    $dt;
}

1;
