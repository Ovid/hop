#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 61;
#use Test::More 'no_plan';

use lib 'lib/', '../lib/';

BEGIN {
    use_ok 'HOP::Stream', ':all' or die;
}

my @exported = qw(
  cutsort
  drop
  filter
  head
  insert
  iterator_to_stream
  list_to_stream
  append
  merge
  node
  promise
  show
  tail
  transform
  upto
  upfrom
);

foreach my $function (@exported) {
    no strict 'refs';
    ok defined &$function, "&$function should be exported to our namespace";
}

# node

ok my $stream = node( 3, 4 ), 'Calling node() should succeed';
is_deeply $stream, [ 3, 4 ], '... returning a stream node';
ok my $new_stream = node( 7, $stream ),
  '... and a node may be in the node() arguments';
is_deeply $new_stream, [ 7, $stream ], '... and the new node should be correct';

# head
is head($new_stream), 7, 'head() should return the head of a node';

# tail

is tail($new_stream), $stream, 'tail() should return the tail of a node';

# drop

ok my $head = drop($new_stream), 'drop() should succeed';
is $head, 7, '... returning the head of the node';
is_deeply $new_stream, $stream,
  '... and setting the tail of the node as the node';

# upto

ok !upto( 5, 4 ),
  'upto() should return false if the first number is greater than the second';
ok $stream = upto( 4, 7 ),
  '... but it should succeed if the first number is less than the second';

my @numbers;
while ( defined( my $num = drop($stream) ) ) {
    push @numbers, $num;
}
is_deeply \@numbers, [ 4, 5, 6, 7 ],
  '... and the stream should return all of the numbers';

# upfrom
ok $stream = upfrom(42), 'upfrom() should return a stream';

@numbers = ();
for ( 1 .. 10 ) {
    push @numbers, drop($stream);
}
is_deeply \@numbers, [ 42 .. 51 ],
  '... which should return the numbers we expect';

# show

show( $stream, 5 );
is show( $stream, 5 ), "52 53 54 55 56 ", 'Show should print the correct values';

# transform

my $evens = transform { $_[0] * 2 } upfrom(1);
ok $evens, 'Calling transform() on a stream should succeed';

@numbers = ();
for ( 1 .. 5 ) {
    push @numbers, drop($evens);
}
is_deeply \@numbers, [ 2, 4, 6, 8, 10 ],
  '... which should return the numbers we expect';

# filter

# forget the parens in the filter and it's an infinite loop
$evens = filter { !( $_[0] % 2 ) } upfrom(1);
ok $evens, 'Calling filter() on a stream should succeed';

@numbers = ();
for ( 1 .. 5 ) {
    push @numbers, drop($evens);
}
is_deeply \@numbers, [ 2, 4, 6, 8, 10 ],
  '... which should return the numbers we expect';

# append

my $stream1 = upto(4, 7);
my $stream2 = upto(12, 15);
my $stream3 = upto(25, 28);
ok $stream = append($stream1, $stream2, $stream3),
  "append() should return a stream";

@numbers = ();
while ( defined( my $num = drop($stream) ) ) {
    push @numbers, $num;
}
is_deeply \@numbers, [ 4..7, 12..15, 25..28 ],
  '... and the stream should return all of the numbers';

# merge

sub scale {
    my ( $s, $c ) = @_;
    transform { $_[0] * $c } $s;
}

my $hamming;
$hamming = node(
    1,
    promise {
        merge(
            scale( $hamming, 2 ),
            merge( scale( $hamming, 3 ), scale( $hamming, 5 ), )
        )
    }
);

@numbers = ();
for ( 1 .. 10 ) {
    push @numbers, drop($hamming);
}
is_deeply \@numbers, [ 1, 2, 3, 4, 5, 6, 8, 9, 10, 12 ],
  'merge() should let us merge sorted streams';

$evens = transform { $_[0] * 2 } upfrom(1);
my $odds = transform { ( $_[0] * 2 ) - 1 } upfrom(1);
my $number = merge( $odds, $evens );

@numbers = ();
for ( 1 .. 10 ) {
    push @numbers, drop($number);
}
is_deeply \@numbers, [ 1 .. 10 ], '... and create the numbers one to ten';

# iterator_to_stream

my @iter = qw/2 4 6 8/;
my $iter = sub { shift @iter };
ok $stream = iterator_to_stream($iter),
  'iterator_to_stream() should convert an iterator to a stream';
@numbers = ();
while ( defined( my $number = drop($stream) ) ) {
    push @numbers, $number;
}
is_deeply \@numbers, [ 2, 4, 6, 8 ],
  '... and the stream should return the correct values';

# list_to_stream

ok my $list = list_to_stream( 1 .. 9, node(10) ),
  'list_to_stream() should return a stream';
@numbers = ();
while ( defined( my $num = drop($list) ) ) {
    push @numbers, $num;
}
is_deeply \@numbers, [ 1 .. 10 ], '... and create the numbers one to ten';

# list_to_stream, final node computed internally

ok $list = list_to_stream( 1 .. 10 ),
  'list_to_stream() should return a stream';
@numbers = ();
while ( defined( my $num = drop($list) ) ) {
    push @numbers, $num;
}
is_deeply \@numbers, [ 1 .. 10 ], '... and create the numbers one to ten';

# insert

my @list = qw/seventeen three one/;                # sorted by descending length
my $compare = sub { length $_[0] < length $_[1] };
insert @list, 'four', $compare;
is_deeply \@list, [qw/seventeen three four one/],
  'insert() should be able to insert items according to our sort criteria';

# 
# streams of array refs do not work properly, because tail [a,b] is b, even if [a,b] is
# the last stream element, and not a node
# Solution: bless nodes, check is_node in head, tail, list_to_stream
#
$stream = list_to_stream( [A => 1], [B => 2] );
is_deeply $stream, 
  bless([ [A => 1], 
          bless([ [B => 2], 
                  undef ],
              'HOP::Stream')],
      'HOP::Stream'), "stream of array refs";
is_deeply head($stream), [A => 1], "... head is array ref";
is_deeply tail($stream), 
  bless([ [B => 2], 
          undef ],
      'HOP::Stream'), "... tail is stream";

drop($stream);
is_deeply $stream, 
  bless([ [B => 2], 
          undef ],
      'HOP::Stream'), "stream of array refs, dropped 1";
is_deeply head($stream), [B => 2], "... head is array ref";
is_deeply tail($stream), undef, "... tail is stream";

drop($stream);
is_deeply $stream, undef, "stream of array refs, dropped 2";
is_deeply head($stream), undef, "... head is undef";
is_deeply tail($stream), undef, "... tail is undef";

drop($stream);
is_deeply $stream, undef, "stream of array refs, dropped 3";
is_deeply head($stream), undef, "... head is undef";
is_deeply tail($stream), undef, "... tail is undef";

# 
# use a non-stream as stream
#
$stream = [1, [2, [3]]];
is head($stream), undef, "no head of non-stream";
is tail($stream), undef, "no head of non-stream";
