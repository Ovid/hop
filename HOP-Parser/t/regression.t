#!/usr/bin/perl
use warnings;
use strict;

use Test::Exception;
use Test::More tests => 3;

use lib 'lib/', '../lib/';
use HOP::Parser ':all';

use HOP::Stream qw/node list_to_stream/;

sub run_parser {
    my ( $parser, $stream ) = @_;
    die "You must call run_parser() in list context"
      unless wantarray;
    return $parser->($stream);
}

my @tokens = (
    node( OP  => '+' ),
    node( VAR => 'x' ),
    node( VAL => 3 ),
    node( VAL => 17 ),
);
my $stream = list_to_stream(@tokens);

#
# concatenate:  we should be able to concatenate stream tokens
#

my $parser = concatenate( match('OP'), match( VAR => 'x' ), );
ok my $optional_parser =
  optional( concatenate( match('OP'), match( VAR => 'x' ) ) ),
  'We should be able to optionally concatenate a multiple parsers';
my ( $parsed,  $remainder )  = $parser->($stream);
my ( $oparsed, $oremainder ) = $optional_parser->($stream);
is_deeply $parsed, $oparsed,
  'And it should parse the same as a regular concat parser, if matching';
is_deeply $remainder, $oremainder, '... and leave the same remainder';
