#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 10;

#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Lexer', ':all' or die;
}

my @input_tokens = (
    [ STR   => qr/\"[^\"]*\"/ ],
    [ EXPR  => qr/ ( [[:alpha:]]+ | \d+ ) /x ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s*/, sub { () } ],
);

# check if we can use capturing parentheses in our expression

my(@text, $iter, $lexer, $token);

# no more tokens after split token
@text	= ('x = a + 25 - b');
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [EXPR => 'x'], 'EXPR';
is_deeply $token = $lexer->(), [OP	 => '='], '=';
is_deeply $token = $lexer->(), [EXPR => 'a'], 'EXPR';
is_deeply $token = $lexer->(), [OP	 => '+'], '+';
is_deeply $token = $lexer->(), [EXPR => 25 ], 'EXPR';
is_deeply $token = $lexer->(), [OP	 => '-'], '-';
is_deeply $token = $lexer->(), [EXPR => 'b'], 'EXPR';
is $token = $lexer->(), undef, 'EOF';
