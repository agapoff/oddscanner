#!/usr/bin/perl

#
# Vitaly Agapov agapov.vitaly@gmail.com
#
# v1.0 2016-01-27
#
# Bookmaker parser
#
use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__);
}
use oddscanner;

my $pid = oddscanner->new(9000)->run();
print "Use 'kill $pid' to stop server.\n";

