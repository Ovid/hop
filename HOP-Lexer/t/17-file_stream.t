#!/usr/bin/perl
use warnings;
use strict;

# RT ID #30385 : return line numbers

use Test::More tests => 9;

#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Lexer', ':all' or die;
	use_ok 'HOP::Stream', ':all' or die;
}

my @input_tokens = (
	{ FILE_POSITION => "file.txt" },		# option : will be overwritten
    [ STR   => qr/\"[^\"]*\"/ ],
    [ VAR   => qr/[[:alpha:]]+/ ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s+/, sub { () } ],
);

isa_ok my $lexer = file_lexer_stream('t/17-file_stream.in', @input_tokens), 
	'HOP::Stream';

my $token;
is_deeply $token = drop($lexer), [VAR	=> 'x',	't/17-file_stream.in' => 2], 'VAR';
is_deeply $token = drop($lexer), [OP	=> '=',	't/17-file_stream.in' => 2], '=';
is_deeply $token = drop($lexer), [NUM	=> 3,	't/17-file_stream.in' => 4], 'NUM';
is_deeply $token = drop($lexer), [OP	=> '+',	't/17-file_stream.in' => 5], '+';
is_deeply $token = drop($lexer), [NUM	=> 4,	't/17-file_stream.in' => 7], 'NUM';
is $token = drop($lexer), undef, 'EOF';
