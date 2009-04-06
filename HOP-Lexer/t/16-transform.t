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
    [ VAR   => qr/[[:alpha:]]+/, sub { my($label, $value) = @_; [$label, uc($value)] } ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s*/, sub { () } ],
);

# check transform functions
my(@text, $iter, $lexer, $token);

# no more tokens after split token
@text	= ('x = a + 25 - b');
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [VAR => 'X'], 'VAR';
is_deeply $token = $lexer->(), [OP	=> '='], '=';
is_deeply $token = $lexer->(), [VAR => 'A'], 'VAR';
is_deeply $token = $lexer->(), [OP	=> '+'], '+';
is_deeply $token = $lexer->(), [NUM	=> 25], 'NUM';
is_deeply $token = $lexer->(), [OP	=> '-'], '-';
is_deeply $token = $lexer->(), [VAR => 'B'], 'VAR';
is $token = $lexer->(), undef, 'EOF';
