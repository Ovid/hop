#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 16;

#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Lexer', ':all' or die;
	use_ok 'HOP::Stream', ':all' or die;
}

my @input_tokens = (
    [ STR   => qr/\"[^\"]*\"/ ],
    [ VAR   => qr/[[:alpha:]]+/ ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s*/, sub { () } ],
);

# accept stream as input
my @text         = qw/ x = 3 + 4 /;
my $stream       = list_to_stream(@text);
isa_ok my $lexer = make_lexer( $stream, @input_tokens ), 'CODE';

my $token;
is_deeply $token = $lexer->(), [VAR	=> 'x'], 'VAR';
is_deeply $token = $lexer->(), [OP	=> '='], '=';
is_deeply $token = $lexer->(), [NUM	=> 3],   'NUM';
is_deeply $token = $lexer->(), [OP	=> '+'], '+';
is_deeply $token = $lexer->(), [NUM	=> 4],   'NUM';
is $token = $lexer->(), undef, 'EOF';

# read as stream
$stream       = list_to_stream(@text);
isa_ok $lexer = make_lexer_stream( $stream, @input_tokens ), 'HOP::Stream';

is_deeply $token = drop($lexer), [VAR	=> 'x'], 'VAR';
is_deeply $token = drop($lexer), [OP	=> '='], '=';
is_deeply $token = drop($lexer), [NUM	=> 3],   'NUM';
is_deeply $token = drop($lexer), [OP	=> '+'], '+';
is_deeply $token = drop($lexer), [NUM	=> 4],   'NUM';
is $token = drop($lexer), undef, 'EOF';

