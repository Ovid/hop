package HOP::Stream;

use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(
  cutsort
  drop
  filter
  head
  insert
  is_node
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

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

=head1 NAME

HOP::Stream - "Higher Order Perl" streams

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

=head1 DESCRIPTION

This package is based on the Stream.pm code from the book "Higher Order Perl",
by Mark Jason Dominus.

A stream is conceptually similar to a linked list. However, we may have an
infinite stream. As infinite amounts of data are frequently taxing to the
memory of most systems, the tail of the list may be a I<promise>. A promise,
in this context, is merely a promise that the code will compute the rest of
the list if necessary. Thus, the rest of the list does not exist until
actually needed.

The documentation here is not complete.  See "Higher Order Perl" by Mark
Dominus for a full explanation.  Further, this is B<ALPHA> code.  Patches
and suggestions welcome.

=head1 EXPORT

The following functions may be exported upon demand.  ":all" may be specified
if you wish everything exported.

=over 4

=item * cutsort

=item * drop

=item * filter

=item * head

=item * insert

=item * iterator_to_stream

=item * list_to_stream

=item * append

=item * merge

=item * node

=item * promise

=item * show

=item * tail

=item * transform

=item * upto

=item * upfrom

=back

=head1 FUNCTIONS

=head2 node

 my $node = node( $head, $tail );

Returns a node for a stream. 

The tail of the node may be a I<promise> to compute the actual tail when
needed.

=cut

sub node {
    my ( $h, $t ) = @_;
    bless [ $h, $t ], __PACKAGE__;
}

##############################################################################

=head2 head

  my $head = head( $node );

This function returns the head of a stream.

=cut

sub head {
    my ($s) = @_;
    return undef unless is_node($s);
    $s->[0];
}

##############################################################################

=head2 tail

 my $tail = tail( $stream ); 

Returns the I<tail> of a stream.

=cut

sub tail {
    my ($s) = @_;
    return undef unless is_node($s);
    
    if ( is_promise( $s->[1] ) ) {
        $s->[1] = $s->[1]->();
    }
    $s->[1];
}

##############################################################################

=head2 is_node

  if ( is_node($tail) ) {
     ...
  }

Returns true if the tail of a node is a node. Generally this function is
used internally.

=cut

sub is_node {
    # Note that this is *not* bad code.  Nodes aren't really objects.  They're
    # merely being blessed to ensure that we can disambiguate them from array
    # references.
    UNIVERSAL::isa( $_[0], __PACKAGE__ );
}

##############################################################################

=head2 is_promise

  if ( is_promise($tail) ) {
     ...
  }

Returns true if the tail of a node is a promise. Generally this function is
used internally.

=cut

sub is_promise {
    UNIVERSAL::isa( $_[0], 'CODE' );
}

##############################################################################

=head2 promise

  my $promise = promise { ... };

A utility function with a code prototype (C<< sub promise(&); >>) allowing one
to specify a coderef with curly braces and omit the C<sub> keyword.

=cut

sub promise (&) { $_[0] }

##############################################################################

=head2 show

 show( $stream, [ $number_of_nodes ] ); 

This is a debugging function that will return a text representation of
C<$number_of_nodes> of the stream C<$stream>.

Omitting the second argument will print all elements of the stream. This is
not recommended for infinite streams (duh).

The elements of the stream will be separated by the current value of C<$">.

=cut

sub show {
    my ( $s, $n ) = @_;
    my $show = '';
    while ( $s && ( !defined $n || $n-- > 0 ) ) {
        $show .= head($s) . $";
        $s = tail($s);
    }
    return $show;
}

##############################################################################

=head2 drop

  my $head = drop( $stream );

This is the C<shift> function for streams. It returns the head of the stream
and and modifies the stream in-place to be the tail of the stream.

=cut

sub drop {
    my $h = head( $_[0] );
    $_[0] = tail( $_[0] );
    return $h;
}

##############################################################################

=head2 transform

  my $new_stream = transform { $_[0] * 2 } $old_stream;

This is the C<map> function for streams. It returns a new stream.

=cut

sub transform (&$) {
    my $f = shift;
    my $s = shift;
    return unless $s;
    node( $f->( head($s) ), promise { transform ( $f, tail($s) ) } );
}

##############################################################################

=head2 filter

  my $new_stream = filter { $_[0] % 2 } $old_stream;

This is the C<grep> function for streams. It returns a new stream.

=cut

sub filter (&$) {
    my $f = shift;
    my $s = shift;
    until ( !$s || $f->( head($s) ) ) {
        drop($s);
    }
    return if !$s;
    node( head($s), promise { filter ( $f, tail($s) ) } );
}

##############################################################################

=head2 merge

  my $merged_stream = merge( $stream1, $stream2 );

This function takes two streams assumed to be in sorted order and merges them
into a new stream, also in sorted order.

=cut

sub merge {
    my ( $S, $T ) = @_;
    return $T unless $S;
    return $S unless $T;
    my ( $s, $t ) = ( head($S), head($T) );
    if ( $s > $t ) {
        node( $t, promise { merge( $S, tail($T) ) } );
    }
    elsif ( $s < $t ) {
        node( $s, promise { merge( tail($S), $T ) } );
    }
    else {
        node( $s, promise { merge( tail($S), tail($T) ) } );
    }
}

##############################################################################

=head2 append

  my $merged_stream = append( $stream1, $stream2 );

This function takes a list of streams and attaches them together head-to-tail
into a new stream.

=cut

sub append {
    my (@streams) = @_;

    while (@streams) {
        my $h = drop( $streams[0] );
        return node( $h, promise { append(@streams) } ) if defined($h);
        shift @streams;
    }
    return undef;
}

##############################################################################

=head2 list_to_stream

  my $stream = list_to_stream(@list);

Converts a list into a stream.  The final item of C<list> should be a promise
or another stream.  Thus, to generate the numbers one through ten, one could
do this:

 my $stream = list_to_stream( 1 .. 9, node(10, undef) );
 # or
 my $stream = list_to_stream( 1 .. 9, node(10) );

=cut

sub list_to_stream {
    my $node = pop;
    $node = node($node) unless is_node($node);    

    while (@_) {
        my $item = pop;
        $node = node( $item, $node );
    }
    $node;
}

##############################################################################

=head2 iterator_to_stream

  my $stream = iterator_to_stream($iterator);

Converts an iterator into a stream.  An iterator is merely a code reference
which, when called, keeps returning elements until there are no more elements,
at which point it returns "undef".

=cut

sub iterator_to_stream {
    my $it = shift;
    my $v  = $it->();
    return unless defined $v;
    node( $v, sub { iterator_to_stream($it) } );
}

##############################################################################

=head2 upto

  my $stream = upto($from_num, $to_num);

Given two numbers, C<$from_num> and C<$to_num>, returns an iterator which will
return all of the numbers between C<$from_num> and C<$to_num>, inclusive.

=cut

sub upto {
    my ( $m, $n ) = @_;
    return if $m > $n;
    node( $m, promise { upto( $m + 1, $n ) } );
}

##############################################################################

=head2 upfrom

  my $stream = upfrom($num);

Similar to C<upto>, this function returns a stream which will generate an 
infinite list of numbers starting from C<$num>.

=cut

sub upfrom {
    my ($m) = @_;
    node( $m, promise { upfrom( $m + 1 ) } );
}

sub insert (\@$$);

sub cutsort {
    my ( $s, $cmp, $cut, @pending ) = @_;
    my @emit;

    while ($s) {
        while ( @pending && $cut->( $pending[0], head($s) ) ) {
            push @emit, shift @pending;
        }

        if (@emit) {
            return list_to_stream( @emit,
                promise { cutsort( $s, $cmp, $cut, @pending ) } );
        }
        else {
            insert( @pending, head($s), $cmp );
            $s = tail($s);
        }
    }

    return list_to_stream( @pending, undef );
}

sub insert (\@$$) {
    my ( $a, $e, $cmp ) = @_;
    my ( $lo, $hi ) = ( 0, scalar(@$a) );
    while ( $lo < $hi ) {
        my $med = int( ( $lo + $hi ) / 2 );
        my $d = $cmp->( $a->[$med], $e );
        if ( $d <= 0 ) {
            $lo = $med + 1;
        }
        else {
            $hi = $med;
        }
    }
    splice( @$a, $lo, 0, $e );
}

=head1 AUTHOR

Mark Dominus, maintained by Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hop-stream@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HOP-Stream>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Many thanks to Mark Dominus and Elsevier, Inc. for allowing this work to be
republished.

=head1 COPYRIGHT & LICENSE

Code derived from the book "Higher-Order Perl" by Mark Dominus, published by
Morgan Kaufmann Publishers, Copyright 2005 by Elsevier Inc.

=head1 ABOUT THE SOFTWARE

All Software (code listings) presented in the book can be found on the
companion website for the book (http://perl.plover.com/hop/) and is
subject to the License agreements below.

=head1 ELSEVIER SOFTWARE LICENSE AGREEMENT

Please read the following agreement carefully before using this Software. This
Software is licensed under the terms contained in this Software license
agreement ("agreement"). By using this Software product, you, an individual,
or entity including employees, agents and representatives ("you" or "your"),
acknowledge that you have read this agreement, that you understand it, and
that you agree to be bound by the terms and conditions of this agreement.
Elsevier inc. ("Elsevier") expressly does not agree to license this Software
product to you unless you assent to this agreement. If you do not agree with
any of the following terms, do not use the Software.

=head1 LIMITED WARRANTY AND LIMITATION OF LIABILITY

YOUR USE OF THIS SOFTWARE IS AT YOUR OWN RISK. NEITHER ELSEVIER NOR ITS
LICENSORS REPRESENT OR WARRANT THAT THE SOFTWARE PRODUCT WILL MEET YOUR
REQUIREMENTS OR THAT ITS OPERATION WILL BE UNINTERRUPTED OR ERROR-FREE. WE
EXCLUDE AND EXPRESSLY DISCLAIM ALL EXPRESS AND IMPLIED WARRANTIES NOT STATED
HEREIN, INCLUDING THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE. IN ADDITION, NEITHER ELSEVIER NOR ITS LICENSORS MAKE ANY
REPRESENTATIONS OR WARRANTIES, EITHER EXPRESS OR IMPLIED, REGARDING THE
PERFORMANCE OF YOUR NETWORK OR COMPUTER SYSTEM WHEN USED IN CONJUNCTION WITH
THE SOFTWARE PRODUCT. WE SHALL NOT BE LIABLE FOR ANY DAMAGE OR LOSS OF ANY
KIND ARISING OUT OF OR RESULTING FROM YOUR POSSESSION OR USE OF THE SOFTWARE
PRODUCT CAUSED BY ERRORS OR OMISSIONS, DATA LOSS OR CORRUPTION, ERRORS OR
OMISSIONS IN THE PROPRIETARY MATERIAL, REGARDLESS OF WHETHER SUCH LIABILITY IS
BASED IN TORT, CONTRACT OR OTHERWISE AND INCLUDING, BUT NOT LIMITED TO,
ACTUAL, SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES. IF THE
FOREGOING LIMITATION IS HELD TO BE UNENFORCEABLE, OUR MAXIMUM LIABILITY TO YOU
SHALL NOT EXCEED THE AMOUNT OF THE PURCHASE PRICE PAID BY YOU FOR THE SOFTWARE
PRODUCT. THE REMEDIES AVAILABLE TO YOU AGAINST US AND THE LICENSORS OF
MATERIALS INCLUDED IN THE SOFTWARE PRODUCT ARE EXCLUSIVE.

YOU UNDERSTAND THAT ELSEVIER, ITS AFFILIATES, LICENSORS, SUPPLIERS AND AGENTS,
MAKE NO WARRANTIES, EXPRESSED OR IMPLIED, WITH RESPECT TO THE SOFTWARE
PRODUCT, INCLUDING, WITHOUT LIMITATION THE PROPRIETARY MATERIAL, AND
SPECIFICALLY DISCLAIM ANY WARRANTY OF MERCHANTABILITY OR FITNESS FOR A
PARTICULAR PURPOSE.

IN NO EVENT WILL ELSEVIER, ITS AFFILIATES, LICENSORS, SUPPLIERS OR AGENTS, BE
LIABLE TO YOU FOR ANY DAMAGES, INCLUDING, WITHOUT LIMITATION, ANY LOST
PROFITS, LOST SAVINGS OR OTHER INCIDENTAL OR CONSEQUENTIAL DAMAGES, ARISING
OUT OF YOUR USE OR INABILITY TO USE THE SOFTWARE PRODUCT REGARDLESS OF WHETHER
SUCH DAMAGES ARE FORESEEABLE OR WHETHER SUCH DAMAGES ARE DEEMED TO RESULT FROM
THE FAILURE OR INADEQUACY OF ANY EXCLUSIVE OR OTHER REMEDY.

=head1 SOFTWARE LICENSE AGREEMENT

This Software License Agreement is a legal agreement between the Author and
any person or legal entity using or accepting any Software governed by this
Agreement. The Software is available on the companion website
(http://perl.plover.com/hop/) for the Book, Higher-Order Perl, which is
published by Morgan Kaufmann Publishers. "The Software" is comprised of all
code (fragments and pseudocode) presented in the book.

By installing, copying, or otherwise using the Software, you agree to be bound
by the terms of this Agreement.

The parties agree as follows:

=over 4

=item 1 Grant of License

We grant you a nonexclusive license to use the Software for any purpose,
commercial or non-commercial, as long as the following credit is included
identifying the original source of the Software: "from Higher-Order Perl by
Mark Dominus, published by Morgan Kaufmann Publishers, Copyright 2005 by
Elsevier Inc".

=item 2 Disclaimer of Warranty. 

We make no warranties at all. The Software is transferred to you on an "as is"
basis. You use the Software at your own peril. You assume all risk of loss for
all claims or controversies, now existing or hereafter, arising out of use of
the Software. We shall have no liability based on a claim that your use or
combination of the Software with products or data not supplied by us infringes
any patent, copyright, or proprietary right. All other warranties, expressed
or implied, including, without limitation, any warranty of merchantability or
fitness for a particular purpose are hereby excluded.

=item 3 Limitation of Liability. 

We will have no liability for special, incidental, or consequential damages
even if advised of the possibility of such damages. We will not be liable for
any other damages or loss in any way connected with the Software.

=back

=cut

1;    # End of HOP::Stream
