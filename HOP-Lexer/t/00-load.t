#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HOP::Lexer' );
}

diag( "Testing HOP::Lexer $HOP::Lexer::VERSION, Perl $], $^X" );
