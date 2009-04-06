#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 13;

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
    [ SPACE => qr/\s+/, sub { () } ],
);

# check if unparsed text is returned as text
my(@text, $iter, $lexer, $token);

@text	= ('2 , 3 ,');
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [NUM	=> 2], 'NUM';
is_deeply $token = $lexer->(), ',', ',';
is_deeply $token = $lexer->(), [NUM	=> 3], 'NUM';
is_deeply $token = $lexer->(), ',', ',';
is $token = $lexer->(), undef, 'EOF';


# check with /\s*/ - causes a problem detecting the next parseable token
# after a no-match
@input_tokens = (
    [ STR   => qr/\"[^\"]*\"/ ],
    [ VAR   => qr/[[:alpha:]]+/ ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s*/, sub { () } ],
);

@text	= ('2 , 3 ,');
$iter	= sub { shift @text };
isa_ok $lexer = make_lexer( $iter, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), [NUM	=> 2], 'NUM';
is_deeply $token = $lexer->(), ',', ',';
is_deeply $token = $lexer->(), [NUM	=> 3], 'NUM';
is_deeply $token = $lexer->(), ',', ',';
is $token = $lexer->(), undef, 'EOF';
