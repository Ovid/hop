#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HOP::Parser' );
}

diag( "Testing HOP::Parser $HOP::Parser::VERSION, Perl $], $^X" );
