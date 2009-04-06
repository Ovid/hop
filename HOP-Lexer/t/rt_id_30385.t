#!/usr/bin/perl
use warnings;
use strict;

# RT ID #30385 : return line numbers

use Test::More tests => 21;

#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Lexer', ':all' or die;
	use_ok 'HOP::Stream', ':all' or die;
}

my @input_tokens = (
	{ FILE_POSITION => "file.txt" },		# option : show file positions
    [ STR   => qr/\"[^\"]*\"/ ],
    [ VAR   => qr/[[:alpha:]]+/ ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s+/, sub { () } ],
);

# input with newlines
my $text = '
x = 

3 
+ 

4

';
my $stream       = list_to_stream($text);
isa_ok my $lexer = make_lexer( $stream, @input_tokens ), 'CODE';

my $token;
is_deeply $token = $lexer->(), [VAR	=> 'x',	"file.txt" => 2], 'VAR';
is_deeply $token = $lexer->(), [OP	=> '=',	"file.txt" => 2], '=';
is_deeply $token = $lexer->(), [NUM	=> 3,	"file.txt" => 4], 'NUM';
is_deeply $token = $lexer->(), [OP	=> '+',	"file.txt" => 5], '+';
is_deeply $token = $lexer->(), [NUM	=> 4,	"file.txt" => 7], 'NUM';
is $token = $lexer->(), undef, 'EOF';


# check for line count in unrecognized text
@input_tokens = (
	{ FILE_POSITION => "file.txt" },		# option : show file positions
    [ STR   => qr/\"[^\"]*\"/ ],
    [ VAR   => qr/[[:alpha:]]+/ ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/ +/, sub { () } ],
);

$stream       = list_to_stream($text);
isa_ok $lexer = make_lexer( $stream, @input_tokens ), 'CODE';

is_deeply $token = $lexer->(), "\n", 'newline';
is_deeply $token = $lexer->(), [VAR	=> 'x',	"file.txt" => 2], 'VAR';
is_deeply $token = $lexer->(), [OP	=> '=',	"file.txt" => 2], '=';
is_deeply $token = $lexer->(), "\n\n", 'newline';
is_deeply $token = $lexer->(), [NUM	=> 3,	"file.txt" => 4], 'NUM';
is_deeply $token = $lexer->(), "\n", 'newline';
is_deeply $token = $lexer->(), [OP	=> '+',	"file.txt" => 5], '+';
is_deeply $token = $lexer->(), "\n\n", 'newline';
is_deeply $token = $lexer->(), [NUM	=> 4,	"file.txt" => 7], 'NUM';
is_deeply $token = $lexer->(), "\n\n", 'newline';
is $token = $lexer->(), undef, 'EOF';
