#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 9;

#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Lexer', ':all' or die;
}

my @input_tokens = (
    [ STR   => qr/\"[^\"]*\"/ ],
    [ VAR   => qr/[[:alpha:]]+/ ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s*/, sub { () } ],
);

# accept input stream of characters, or already processed tokens

my(@text, $iter, $lexer, $token);

# no more tokens after split token
@text	= ([OP => '*'], '', '2', '', '3', '', [OP => '*'], [OP => '*'], 45, [OP => '*']);
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [OP	=> '*'], '*';
is_deeply $token = $lexer->(), [NUM	=> 23], 'NUM';
is_deeply $token = $lexer->(), [OP	=> '*'], '*';
is_deeply $token = $lexer->(), [OP	=> '*'], '*';
is_deeply $token = $lexer->(), [NUM	=> 45], 'NUM';
is_deeply $token = $lexer->(), [OP	=> '*'], '*';
is $token = $lexer->(), undef, 'EOF';

