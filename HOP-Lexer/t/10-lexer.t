#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 8;

#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Lexer', ':all' or die;
}


my @exported = qw(
  make_lexer
  string_lexer
);

foreach my $function (@exported) {
    no strict 'refs';
    ok defined &$function, "&$function should be exported to our namespace";
}

my $text         = 'x = 3 + 4';
my @text         = ($text);
my $iter         = sub { shift @text };
my @input_tokens = (
    [ VAR   => qr/[[:alpha:]]+/ ],
    [ NUM   => qr/\d+/ ],
    [ OP    => qr/[-+=]/ ],
    [ SPACE => qr/\s*/, sub { () } ],
);

ok my $lexer = make_lexer( $iter, @input_tokens ),
  'Calling make_lexer() with valid arguments should succeed';

my @tokens;
while ( my $token = $lexer->() ) {
    push @tokens, $token;
    if ( "NUM 3" eq "@$token" ) {
        my $next_token = $lexer->('peek');
        is_deeply $next_token, [ OP => '+' ],
          '... and $lexer->("peek") should return the next token without advancing';
    }
}

my @expected = (
    [ VAR => 'x' ],
    [ OP  => '=' ],
    [ NUM => 3 ],
    [ OP  => '+' ],
    [ NUM => 4 ],
);
is_deeply \@tokens, \@expected, '... and it should return the correct tokens';

ok $lexer = string_lexer( $text, @input_tokens ),
  'Calling string_lexer() with a string should succeed';

@tokens = ();
while ( my $token = $lexer->() ) {
    push @tokens, $token;
}

@expected = (
    [ VAR => 'x' ],
    [ OP  => '=' ],
    [ NUM => 3 ],
    [ OP  => '+' ],
    [ NUM => 4 ],
);
is_deeply \@tokens, \@expected, '... and it should return the correct tokens';
