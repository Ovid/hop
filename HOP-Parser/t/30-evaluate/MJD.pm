#
# Package.
#

package MJD;

#
# Dependencies.
#

use HOP::Parser qw( :all );
use HOP::Lexer;
use HOP::Stream qw( :all );

#
# Exports.
#

use Exporter;

use vars qw( $VERSION @ISA @EXPORT %EXPORT_TAGS );

@ISA = qw( Exporter );

@EXPORT_OK = qw(
  evaluate
  evaluate_with_lexer_stream
  identifiers
  make_lexer
  make_lexer_stream
);
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#
# No more mister nice guy.
#

use strict;
use warnings;

#
# Constants.
#

use constant LEXEMES => (
  [ T800        => qr/ ;\n* | \n+        /x                                           ],
  [ HEXADECIMAL => qr/ 0x[0-9a-f]+       /xi => sub { [ UNSIGNED => h2u ( $_[1] ) ] } ],
  [ UNSIGNED    => qr/ \d+               /x                                           ],
  [ RETURN      => qr/ \b return \b      /x                                           ],
  [ ID          => qr/ [A-Za-z]\w*       /x                                           ],
  [ OP          => qr/ \*\* | [-=+*\/()] /x                                           ],
  [ WHITESPACE  => qr/ \s+               /x  => sub { '' }                            ],
);

#
# Variables.
#

my ( $ID, $RETURN );

#
# Functions.
#

=head1 FUNCTIONS

=cut

my ( $base, $expression, $factor, $program, $statement, $term );
my ( $Base, $Expression, $Factor, $Program, $Statement, $Term );

$Base       = parser { $base->(@_)       };
$Expression = parser { $expression->(@_) };
$Factor     = parser { $factor->(@_)     };
$Program    = parser { $program->(@_)    };
$Statement  = parser { $statement->(@_)  };
$Term       = parser { $term->(@_)       };

$program = concatenate(star($Statement) => \&End_of_Input);

$statement = alternate(
  T(concatenate(lookfor('RETURN') => $Expression => lookfor('T800')),
    sub { $RETURN = $_[1] }),
  T(concatenate(lookfor('ID') => lookfor([OP => '=']) => $Expression => lookfor('T800')),
    sub { $ID->{$_[0]} = $_[2] }),
  error(lookfor('T800'), $Statement),
);

$expression = operator($Term,
  [lookfor([OP => '+']), sub { $_[0] + $_[1] }],
  [lookfor([OP => '-']), sub { $_[0] - $_[1] }]);

$term = operator($Factor,
  [lookfor([OP => '*']), sub { $_[0] * $_[1] }],
  [lookfor([OP => '/']), sub { $_[0] / $_[1] }]);
  
$factor = T(
  concatenate(
    $Base =>
    alternate(
      T(concatenate(lookfor([OP => '**']) => $Factor), sub { $_[1] } ),
      T(\&nothing, sub { 1 }))),
  sub { $_[0] ** $_[1] }
);

$base = alternate(
  lookfor('UNSIGNED'),
  lookfor(ID => sub { $ID->{$_[0][1]} || 0 }),
  T(concatenate(lookfor([OP => '(']) => $Expression => lookfor([OP => ')'])), sub { $_[1] })
);

=head2 make_lexer

  make_lexer ( @statements )

Returns a L<HOP::Lexer> lexer.

=cut

sub make_lexer {
  my @i = map { s/\bx\b/*/g ; s/(?<!;)$/;/ ; $_ } @_;
  
  HOP::Lexer::make_lexer ( sub { shift @i }, LEXEMES );
}

=head2 make_lexer_stream

  make_lexer_stream ( @statements )

Returns a L<HOP::Stream> stream from a L<HOP::Lexer> lexer.

=cut

sub make_lexer_stream {
  iterator_to_stream ( make_lexer ( @_ ) );
}

=head2 identifiers

  identifiers ( $stream )

Returns sorted list of lexer stream identifiers.

=cut

sub identifiers {
  my $stream = filter { $_[0][0] eq 'ID' } shift;
  
  my $ids;
  transform { $ids->{$_[0][1]}++ } $stream;
  
  sort keys %$ids;
}

=head2 evaluate_with_lexer_stream

  evaluate_with_lexer_stream ( $stream )

Returns evaluated 'return' statement from input stream lexer.

=cut

sub evaluate_with_lexer_stream {
  undef $ID;
  undef $RETURN;
  $program->( shift );
  $RETURN;
}

=head2 evaluate

  evaluate ( @statements )

Returns evaluated 'return' statement from input statements.

=cut

sub evaluate {
  evaluate_with_lexer_stream ( make_lexer_stream ( @_ ) );
}

use constant HEX_RE => qr/^0x[0-9a-f]+$/i;

=head2 u2h

  h2u ( $unsigned )

Unsigned (integer) to hexadecimal conversion routine.

=cut

sub u2h {
 #assert_nonblank $_[0];
  
  $_[0] =~ HEX_RE ? shift : sprintf '0x%X' => shift;
}

=head2 h2u

  h2u ( $hexadecimal )

Hexadecimal to unsigned (integer) conversion routine.

=cut

sub h2u {
  my ( $h ) = @_;
  
 #assert_like $_[0] => HEX_RE;
  
  $h =~ s/^0x//i;

  my $h2u = {
    0 =>  0, 1 =>  1, 2 =>  2, 3 =>  3,
    4 =>  4, 5 =>  5, 6 =>  6, 7 =>  7,
    8 =>  8, 9 =>  9, a => 10, b => 11,
    c => 12, d => 13, e => 14, f => 15,
  };

  my ( $u, $n );
  $u += $h2u->{lc( $_ )} * ( 16 ** $n++ ) for reverse split( '', $h );

  $u;
}

#
# End of MJD.
#

1;
