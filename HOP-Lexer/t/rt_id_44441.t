#!/usr/bin/perl
use warnings;
use strict;

# RT ID #44441 : Nested patterns of same precedence are not lexed correctly

use Test::More tests => 5;

BEGIN {
    use_ok 'HOP::Lexer', ':all' or die;
}

my @tokens = (
	['DOUBLEQUOTE', 	qr/"[^"]*"/],
	['SINGLEQUOTE', 	qr/'[^']*'/],
	['SPACES',		 	qr/\s+/, 	sub { return (); }]
);

my $string = q/'"a"' "'b'"/;

isa_ok my $lexer = HOP::Lexer::string_lexer($string, @tokens), 'CODE';
my $token;

is_deeply $token = $lexer->(), ['SINGLEQUOTE', q/'"a"'/], "SINGLEQUOTE";
is_deeply $token = $lexer->(), ['DOUBLEQUOTE', q/"'b'"/], "DOUBLEQUOTE";
is $token = $lexer->(), undef, "EOF";
