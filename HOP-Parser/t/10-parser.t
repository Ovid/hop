#!/usr/bin/perl
use warnings;
use strict;

use Test::Exception;
use Test::More tests => 128;
#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Parser', ':all' or die;
}

use HOP::Stream qw/node list_to_stream/;

sub run_parser {
    my ( $parser, $stream ) = @_;
    die "You must call run_parser() in list context"
      unless wantarray;
    return $parser->($stream);
}

my @exported = qw(
  absorb
  action
  alternate
  concatenate
  debug
  End_of_Input
  error
  list_of
  list_values_of
  lookfor
  match
  nothing
  null_list
  operator
  optional
  parser
  rlist_of
  rlist_values_of
  star
  T
  test
);

foreach my $function (@exported) {
    no strict 'refs';
    ok defined &$function, "&$function should be exported to our namespace";
}

#
# parser: test that parser accepts a bare block as a subroutine
#

ok my $sub = parser {'Ovid'}, 'parser() should accept a bare block as a sub';
is $sub->(), 'Ovid', '... and we should be able to call the sub';

#
# Begin testing special purpose parsers
#

#
# nothing
#

my ( $parsed, $remainder ) = nothing("anything");
ok !defined $parsed, 'nothing() will always return "undef" for what was parsed';
is_deeply $remainder, "anything", '... and should return the input unaltered';

#
# End_of_Input
#

dies_ok { End_of_Input("anything") }
  'End_of_Input() should fail if data left in the stream';

my @succeeds = End_of_Input(undef);
ok @succeeds, '... and it should succeed if no data is left in the stream';

#
# null_list
#

( $parsed, $remainder ) = null_list("anything");
is_deeply $parsed, [], 'The null_list() parser should always succeed';
is_deeply $remainder, "anything", '... and return the input as the remainder';

#
# Begin testing parser generators
#

#
# lookfor: test passing a bare label
#

ok my $parser = lookfor('OP'),
  'lookfor() should return a parser which can look for tokens.';

dies_ok { $parser->( [ [ 'VAL' => 3 ] ] ) }
  '... and the parser will fail if the first token does not match';

my @tokens = (
    node( OP  => '+' ),
    node( VAR => 'x' ),
    node( VAL => 3 ),
    node( VAL => 17 ),
);
my $stream = list_to_stream(@tokens);
( $parsed, $remainder ) = $parser->($stream);
ok $parsed, 'The lookfor() parser should succeed if the first token matches';
is $parsed, '+', '... returning what we are looking for';
my $expected = [ [ 'VAR', 'x' ], [ [ 'VAL', 3 ], [ 'VAL', 17 ] ] ];
is_deeply $remainder, $expected, '... and then the rest of the stream';

#
# lookfor: test passing a [ $label ]
#

ok $parser = lookfor( ['OP'] ),
  'lookfor() should return a parser if we supply an array ref with a label';

dies_ok { $parser->( [ [ 'VAL' => 3 ] ] ) }
  '... and the parser will fail if the first token does not match';

( $parsed, $remainder ) = $parser->($stream);
ok $parsed, 'The lookfor() parser should succeed if the first token matches';

is $parsed, '+', '... returning what we are looking for';
is_deeply $remainder, $expected, '... and then the rest of the stream';

#
# lookfor: test passing a [ $label, $value ]
#

ok $parser = lookfor( [ OP => '+' ] ),
  'lookfor() should succeed if we supply an array ref with a "label => value"';

dies_ok { $parser->( [ [ 'VAL' => 3 ] ] ) }
  '... and the parser will fail if the first token does not match';

( $parsed, $remainder ) = $parser->($stream);
ok $parsed, 'The lookfor() parser should succeed if the first token matches';

is $parsed, '+', '... returning what we are looking for';
is_deeply $remainder, $expected, '... and then the rest of the stream';

my %opname_for = (
    '+' => 'plus',
    '-' => 'minus',
);
my $get_value = sub {
    my $value = $_[0][1];    # token is [ $label, $value ]
    return exists $opname_for{$value} ? $opname_for{$value} : $value;
};

#
# lookfor: test passing a [ $label ], \&get_value
#

ok $parser = lookfor( ['OP'], $get_value ),
  'lookfor() should succeed if we supply an array ref with a "label => value"';

dies_ok { $parser->( [ [ 'VAL' => 3 ] ] ) }
  '... and the parser will fail if the first token does not match';

( $parsed, $remainder ) = $parser->($stream);
ok $parsed, 'The lookfor() parser should succeed if the first token matches';

is $parsed, 'plus', '... returning the transformed value';
is_deeply $remainder, $expected, '... and then the rest of the stream';

( $parsed, $remainder ) = $parser->( [ [ OP => '-' ] ] );
is $parsed, 'minus', '... and other transformed values should work';

( $parsed, $remainder ) = $parser->( [ [ OP => '*' ] ] );
is $parsed, '*', '... just like we expect them to';

$get_value = sub {
    my ( $matched_token, $opname_for ) = @_;
    my $value = $matched_token->[1];    # token is [ $label, $value ]
    return exists $opname_for->{$value} ? $opname_for->{$value} : $value;
};

#
# lookfor: test passing a [ $label ], \&get_value, $param
#

ok $parser = lookfor( ['OP'], $get_value, \%opname_for ),
  'lookfor() should succeed with the three argument syntax';

dies_ok { $parser->( [ [ 'VAL' => 3 ] ] ) }
  '... and the parser will fail if the first token does not match';

( $parsed, $remainder ) = $parser->($stream);
ok $parsed, 'The lookfor() parser should succeed if the first token matches';

is $parsed, 'plus', '... returning the transformed value';
is_deeply $remainder, $expected, '... and then the rest of the stream';

( $parsed, $remainder ) = $parser->( [ [ OP => '-' ] ] );
is $parsed, 'minus', '... and other transformed values should work';

( $parsed, $remainder ) = $parser->( [ [ OP => '*' ] ] );
is $parsed, '*', '... just like we expect them to';

#
# match: test passing a $label
#

ok $parser = match('OP'), 'match() should return a parser if we supply a label';

dies_ok { $parser->( [ [ 'VAL' => 3 ] ] ) }
  '... and the parser will fail if the first token does not match';

( $parsed, $remainder ) = $parser->($stream);
ok $parsed, 'The match() parser should succeed if the first token matches';

is $parsed, '+', '... returning what we are looking for';
is_deeply $remainder, $expected, '... and then the rest of the stream';

#
# match:  test passing a $label, $value
#

ok $parser = match( OP => '+' ),
  'match() should succeed if we supply a "label => value"';

dies_ok { $parser->( [ [ 'VAL' => 3 ] ] ) }
  '... and the parser will fail if the first token does not match';

( $parsed, $remainder ) = $parser->($stream);
ok $parsed, 'The match() parser should succeed if the first token matches';

is $parsed, '+', '... returning what we are looking for';
is_deeply $remainder, $expected, '... and then the rest of the stream';

#
# concatenate:  we should be able to concatenate stream tokens
#

ok $parser = concatenate(), 'We should be able to concatenate nothing';
( $parsed, $remainder ) = $parser->($stream);
ok !defined $parsed, '... and it should return an undefined parse';
is_deeply $remainder, $stream, '... and the input should be unchanged';

ok $parser = concatenate( match('OP') ),
  'We should be able to concatenate a single parser';
( $parsed, $remainder ) = $parser->($stream);
is $parsed, '+', '... and it should parse the stream';
is_deeply $remainder, $expected,
  '... and the input should be the rest of the stream';

ok $parser = concatenate( match('OP'), match( VAR => 'x' ), ),
  'We should be able to concatenate multiple parsers';
( $parsed, $remainder ) = $parser->($stream);
is_deeply $parsed, [qw/ + x /], '... and it should parse the stream';
my $expected_remainder = [ [ 'VAL', 3 ], [ 'VAL', 17 ] ];
is_deeply $remainder, $expected_remainder,
  '... and the input should be the rest of the stream';

ok $parser = concatenate( match('OP'), match( VAR => 'no such var' ), ),
  'We should be able to concatenate multiple parsers';
dies_ok { $parser->($stream) }
  '... but the parser should fail if the tokens do not match';

ok $parser = concatenate(
    match('OP'),
    match( VAR => 'x' ),
    match( VAL => 3 ),
    match( VAL => 17 ),
  ),
  'We should be able to concatenate multiple parsers';

( $parsed, $remainder ) = $parser->($stream);
is_deeply $parsed, [qw/ + x 3 17 /],
  '... and it should be able to parse the entire stream';

#
# alternate:  we should be able to alternate stream tokens
#

ok $parser = alternate(), 'We should be able to alternate nothing';
@succeeds = $parser->($stream);
ok !@succeeds, '... but it should always fail';

ok $parser = alternate( match('VAR'), match('VAL') ),
  'We should be able to alternate on incorrect tokens';
dies_ok { $parser->($stream) } '... but it should always fail';

( $parsed, $remainder ) =
  run_parser( alternate( match('Foo'), match('OP') ), $stream );
is $parsed, '+', 'alternate() should succeed even if one match is bad';
is_deeply $remainder, $expected,
  '... and the remainder should be the rest of the stream';

( $parsed, $remainder ) =
  run_parser( alternate( match('OP'), match('Foo') ), $stream );
is $parsed, '+', '... regardless of the order they are in';
is_deeply $remainder, $expected,
  '... and the remainder should be the rest of the stream';

( $parsed, $remainder ) =
  run_parser( alternate( match('OP'), match('OP') ), $stream );
is $parsed, '+', '... or if they are duplicate tokens';
is_deeply $remainder, $expected,
  '... and the remainder should be the rest of the stream';

( $parsed, $remainder ) = run_parser(
    alternate(
        match('VAL'), match('Foo'), match('BAR'), match('~'),
        match('OP'),  match('INT'),
    ),
    $stream
);
is $parsed, '+',
  'We should be able to alternate over an arbitrary amount of tokens';
is_deeply $remainder, $expected,
  '... and the remainder should be the rest of the stream';

#
# star:  generates a "zero or more" parser
#

( $parsed, $remainder ) = run_parser( star( match('Foo') ), $stream );
is_deeply $parsed, [], 'The star() parser should always succeed';
is_deeply $remainder, $stream,
  '... and return the input as the remainder if it did not match';

( $parsed, $remainder ) = run_parser( star( match('OP') ), $stream );
is_deeply $parsed, ['+'],
  'The star() parser should return the first value if matched';
is_deeply $remainder, $expected, '... and then the remainder of the stream';

( $parsed, $remainder ) =
  run_parser( star( alternate( match('VAR'), match('OP') ) ), $stream );
is_deeply $parsed, [ '+', 'x' ],
  'The star() parser should return all the values matched';
is_deeply $remainder, [ [ VAL => 3 ], [ VAL => 17 ] ],
  '... and then the remainder of the stream';

( $parsed, $remainder ) =
  run_parser( star( alternate( match('VAL'), match('VAR'), match('OP') ) ),
    $stream );
is_deeply $parsed, [ '+', 'x', 3, 17 ],
  'The star() parser should return all the values matched';
ok !defined $remainder, '... and should be able to match an entire stream';

@tokens = (
    node( FOO => 1 ),
    node( FOO => 2 ),
    node( FOO => 3 ),
    node( FOO => 4 ),
    node( FOO => 5 ),
    node( BAR => 6 ),
    node( FOO => 7 ),
);
my $foo_stream = list_to_stream(@tokens);
( $parsed, $remainder ) = run_parser( star( match('FOO') ), $foo_stream );
is_deeply $parsed, [qw/1 2 3 4 5/], 'star() be able to slurp up multiple items';
is_deeply $remainder, [ [ BAR => 6 ], [ FOO => 7 ] ],
  '... and return the rest of the stream';

#
# list_of
#

@tokens = (
    node( INT   => 2 ),
    node( COMMA => ',' ),
    node( INT   => 7 ),
    node( COMMA => ',' ),
    node( INT   => 4 ),
    node( COMMA => ',' ),
);
my $int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( list_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [ 2, ',', 7, ',', 4 ],
  'The list_of() parser should return all the values matched';
is_deeply $remainder, [ [ COMMA => ',' ] ],
  '... and then the remainder of the stream';

@tokens = (
    node( INT       => 2 ),
    node( NOT_COMMA => ',' ),
    node( INT       => 7 ),
    node( COMMA     => ',' ),
    node( INT       => 4 ),
    node( COMMA     => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( list_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [2],
  'The list_of() parser should be able to match just one item in a list';

@tokens = (
    node( INT => 2 ),
    node( SEP => ',' ),
    node( INT => 7 ),
    node( SEP => ',' ),
    node( INT => 4 ),
    node( SEP => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( list_of( match('INT'), match('SEP') ), $int_list_stream );
is_deeply $parsed, [ 2, ',', 7, ',', 4 ],
  '... and it should allow us to override the separator';
is_deeply $remainder, [ [ SEP => ',' ] ],
  '... and then the remainder of the stream';

#
# list_values_of
#

@tokens = (
    node( INT   => 2 ),
    node( COMMA => ',' ),
    node( INT   => 7 ),
    node( COMMA => ',' ),
    node( INT   => 4 ),
    node( COMMA => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( list_values_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [qw/ 2 7 4 /],
  'The list_values_of() parser should return all the values matched';
is_deeply $remainder, [ [ COMMA => ',' ] ],
  '... and then the remainder of the stream';

@tokens = (
    node( INT       => 2 ),
    node( NOT_COMMA => ',' ),
    node( INT       => 7 ),
    node( COMMA     => ',' ),
    node( INT       => 4 ),
    node( COMMA     => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( list_values_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [2],
  'The list_values_of() parser should be able to match just one item in a list';

@tokens = (
    node( INT => 2 ),
    node( SEP => ',' ),
    node( INT => 7 ),
    node( SEP => ',' ),
    node( INT => 4 ),
    node( SEP => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( list_values_of( match('INT'), match('SEP') ), $int_list_stream );
is_deeply $parsed, [qw/ 2 7 4 /],
  '... and it should allow us to override the separator';
is_deeply $remainder, [ [ SEP => ',' ] ],
  '... and then the remainder of the stream';

#
# rlist_of
#

@tokens = (
    node( COMMA => ',' ),
    node( INT   => 2 ),
    node( COMMA => ',' ),
    node( INT   => 7 ),
    node( COMMA => ',' ),
    node( INT   => 4 ),
    node( COMMA => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( rlist_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [ ',', 2, ',', 7, ',', 4 ],
  'The rlist_of() parser should return all the values matched';
is_deeply $remainder, [ [ COMMA => ',' ] ],
  '... and then the remainder of the stream';

@tokens = (
    node( COMMA     => ',' ),
    node( INT       => 2 ),
    node( NOT_COMMA => ',' ),
    node( INT       => 7 ),
    node( COMMA     => ',' ),
    node( INT       => 4 ),
    node( COMMA     => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( rlist_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [ ',', 2 ],
  'The rlist_of() parser should be able to match just one item in a list';

@tokens = (
    node( SEP => ',' ),
    node( INT => 2 ),
    node( SEP => ',' ),
    node( INT => 7 ),
    node( SEP => ',' ),
    node( INT => 4 ),
    node( SEP => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( rlist_of( match('INT'), match('SEP') ), $int_list_stream );
is_deeply $parsed, [ ',', 2, ',', 7, ',', 4 ],
  '... and it should allow us to override the separator';
is_deeply $remainder, [ [ SEP => ',' ] ],
  '... and then the remainder of the stream';

#
# rlist_values_of
#

@tokens = (
    node( COMMA => ',' ),
    node( INT   => 2 ),
    node( COMMA => ',' ),
    node( INT   => 7 ),
    node( COMMA => ',' ),
    node( INT   => 4 ),
    node( COMMA => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( rlist_values_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [qw/ 2 7 4 /],
  'The rlist_values_of() parser should return all the values matched';
is_deeply $remainder, [ [ COMMA => ',' ] ],
  '... and then the remainder of the stream';

@tokens = (
    node( COMMA     => ',' ),
    node( INT       => 2 ),
    node( NOT_COMMA => ',' ),
    node( INT       => 7 ),
    node( COMMA     => ',' ),
    node( INT       => 4 ),
    node( COMMA     => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( rlist_values_of( match('INT') ), $int_list_stream );
is_deeply $parsed, [2],
'The rlist_values_of() parser should be able to match just one item in a list';

@tokens = (
    node( SEP => ',' ),
    node( INT => 2 ),
    node( SEP => ',' ),
    node( INT => 7 ),
    node( SEP => ',' ),
    node( INT => 4 ),
    node( SEP => ',' ),
);
$int_list_stream = list_to_stream(@tokens);

( $parsed, $remainder ) =
  run_parser( rlist_values_of( match('INT'), match('SEP') ), $int_list_stream );
is_deeply $parsed, [qw/ 2 7 4 /],
  '... and it should allow us to override the separator';
is_deeply $remainder, [ [ SEP => ',' ] ],
  '... and then the remainder of the stream';

#
# optional()
#

@tokens = ( node( 'FOO' => 1 ), node( 'FOO' => 2 ), );
$foo_stream = list_to_stream(@tokens);
( $parsed, $remainder ) = run_parser( optional( match('FOO') ), $foo_stream );
is_deeply $parsed, [1], 'optional() should be able to match an item';
is_deeply $remainder, [ [ FOO => 2 ] ], '... but only one of that item';

@tokens = ( node( 'OOF' => 1 ), node( 'FOO' => 1 ), node( 'FOO' => 2 ), );
$foo_stream = list_to_stream(@tokens);
( $parsed, $remainder ) = run_parser( optional( match('FOO') ), $foo_stream );
is_deeply $parsed, [], 'optional() should mean the item is not required';
is_deeply $remainder, $foo_stream,
  '... and we should return the stream unchanged';
