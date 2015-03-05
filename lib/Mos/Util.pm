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

sub datetime_from_db ($) {
    my $dt = DateTime::Format::MySQL->parse_datetime( shift );
    $dt->set_time_zone($Mos::Util::TIME_ZONE);
    $dt->set_formatter( DateTime::Format::MySQL->new );
    $dt;
}

1;
