#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HOP::Stream' );
}

diag( "Testing HOP::Stream $HOP::Stream::VERSION, Perl $], $^X" );
