#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 14;

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

# check if we can detect a token across several returns from the input iterator

my(@text, $iter, $lexer, $token);

# no more tokens after split token
@text	= ('"a big ', 
		   'continuing ',
		   'string"');
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [STR => '"a big continuing string"'], 'STR';
is $token = $lexer->(), undef, 'EOF';

# one token after split token
@text	= ('"a big ', 
		   'continuing ',
		   'string" + 25');
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [STR	=> '"a big continuing string"'], 'STR';
is_deeply $token = $lexer->(), [OP	=> '+'], '+';
is_deeply $token = $lexer->(), [NUM	=> 25], 'NUM';
is $token = $lexer->(), undef, 'EOF';

# partial match across iterator inputs
@text	= ('',
		   '2',
		   '',
		   '5',
		   '',
		   '0',
		   '',
		   '+',
		   '',
		   '1',
		   '',
		   '5');
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [NUM	=> 250], 'NUM';
is_deeply $token = $lexer->(), [OP	=> '+'], '+';
is_deeply $token = $lexer->(), [NUM	=> 15], 'NUM';
is $token = $lexer->(), undef, 'EOF';

