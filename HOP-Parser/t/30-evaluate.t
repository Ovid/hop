#!/usr/local/bin/perl

#
# Pragmas.
#

use strict;
use warnings;

use lib qw( t/30-evaluate lib );

#
# Modules.
#

use Test::More;

#
# Use cases.
#

my @use_cases = (
  [ '0x10 * CS_number + 0x00'     => '0x20' ],
  [ '0x10 * CS_number + 0x04'     => '0x24' ],
  [ '0x10 * CS_number + 0x08'     => '0x28' ],
  [ '0x10 * CS_number + 0x0C'     => '0x2C' ],
  
  [ '0x10*CS_number+0x0C'         => '0x2C' ],
  [ '0x10*0x02+0x0C'              => '0x2C' ],
  [ '0x10*0x2+0x0C'               => '0x2C' ],
  [ '0x10*2+0x0C'                 => '0x2C' ],
  
  [ '( 0x10 * CS_number ) + 0x0C' => '0x2C' ],
  [ '0x10 * ( CS_number + 0x02 )' => '0x40' ],
  [ '(0x10*CS_number)+0x0C'       => '0x2C' ],
  [ '0x10*(CS_number+0x02)'       => '0x40' ],
);

#
# Test plan.
#

plan ( tests => 1 + @use_cases );

use_ok ( 'MJD' => qw( :all ) );

#
# Core.
#

for ( @use_cases ) {
  my ( $statement, $golden ) = @$_;
  
  my $stream = make_lexer_stream ( my @statements = ( "return $statement;" ) );
  
  unshift @statements, "$_ = 2;" for identifiers ( $stream );
  
  is ( MJD::u2h ( evaluate ( @statements ) ), $golden, "@statements [$golden]" );
}
