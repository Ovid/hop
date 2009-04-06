package HOP::Lexer;

use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK   = qw/ make_lexer make_lexer_stream string_lexer file_lexer_stream /;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use HOP::Stream qw/ node head drop iterator_to_stream /;

=head1 NAME

HOP::Lexer - "Higher Order Perl" Lexer

=head1 VERSION

Version 0.032b

=cut

our $VERSION = '0.032b';

=head1 SYNOPSIS

   use HOP::Lexer ':all';
   use HOP::Stream 'drop', 'iterator_to_stream';

   my @input_tokens = (
      [ 'VAR',   qr/[[:alpha:]]+/    ],
      [ 'NUM',   qr/\d+/             ],
      [ 'OP',    qr/[+=]/            ],
      [ 'SPACE', qr/\s+/, sub { () } ],
      { FILE_POSITION => $file_name },
   );
   
   my $text  = 'x = 3 + 4';
   my $lexer = string_lexer( $text, @input_tokens );
   
   my @tokens;
   while ( my $token = $lexer->() ) {
       push @tokens, $token;
   }
   
   open(my $fh, $file);
   my $lexer = make_lexer( sub {<$fh>}, @input_tokens );
   while ( my $token = $lexer->() ) {
       push @tokens, $token;
   }
   
   open(my $fh, $file);
   my $input_stream = iterator_to_stream(sub {<$fh>});
   my $lexer_stream = make_lexer_stream( $input_stream, @input_tokens );
   while ( my $token = drop($lexer_stream) ) {
       push @tokens, $token;
   }
   
   my $file_stream = file_lexer_stream($file, @input_tokens);
   while ( my $token = drop($lexer_stream) ) {
       push @tokens, $token;
   }

=head1 EXPORT

Four functions may be exported, C<make_lexer>, C<make_lexer_stream>, C<string_lexer>
and C<file_lexer_stream>.

=head1 FUNCTIONS

=head2 make_lexer

=head2 make_lexer_stream

 my $lexer = make_lexer( $input_iterator, @tokens );  
 my $lexer_stream = make_lexer_stream( $input_iterator, @tokens );  

The C<make_lexer> and C<make_lexer_stream> functions expect an input data iterator 
as the first argument and a series of tokens as subsequent arguments. 
They return a stream of lexed tokens: the C<make_lexer> as an iterator, and 
the C<make_lexer_stream> as a stream (see L<HOP::Stream>). 

The output tokens are retrieved with:

    use HOP::Stream 'drop';
    my $token = $lexer->();
    my $token = drop($lexer_stream);

The next output token can be peeked on the stream without consuming it by:

    use HOP::Stream 'head';
    my $token = $lexer->('peek');
    my $token = head($lexer_stream);

The output tokens are two element arrays (but see the option C<FILE_POSITION> below):

 [ $label, $matched_text ]

The C<@tokens> can contain a hash reference with options. The following option 
is available:

=over 4

=item * { FILE_POSITION => $file_name }

If this option is given, the output tokens are changed to four element arrays:

 [ $label, $matched_text, $file_name, $line_nr ]

where $file_name is the name given in the option, and $line_nr is the line in the 
input where the token starts. The first line is numbered 1, and is incremented 
for each C<\n> character found in the input. 

This option is usefull in a parser to give meaningfull error messages at the token
location. The file name is also included to allow the input stream to contain 
lines from different files, e.g. because of a file include mechanism.

See also the C<file_lexer_stream> function below.

=back

The C<$input_iterator> should be either a subroutine reference that returns 
the next value merely by calling the subroutine with no arguments, or a
stream of the next values (see L<HOP::Stream>).  

If you have a single
block of text in a scalar that you want lexed, see the C<string_lexer>
function.

The input C<@tokens> array passed into C<make_lexer> is expected to be a list
of array references with two mandatory items and one optional one:

 [ $label, qr/$match/, &transform ]

=over 4

=item * C<$label>

The C<$label> is the name used for the first item in an output token.

=item * C<$match>

The C<$match> is either an exact string or regular expression which matches
the text the label is to identify.

=item * C<&transform>

The C<&transform> subroutine reference is optional. If supplied, this will
take the matched text and should return a token matching an output token or
an empty list if the token is to be discarded. For example, to discard
whitespace (the label is actually irrelevant, but it helps to document the
code):

 [ 'WHITESPACE', qr/\s+/, sub {()} ]

The two arguments supplied to the transformation subroutine are the label and
value. Thus, if we wish to force all non-negative integers to have a unary
plus, we might do something like this:

 [ 
   'REVERSED INT',  # the label
   /[+-]?\d+/,      # integers with an optional unary plus or minus
   sub { 
     my ($label, $value) = @_;
     $value = "+$value" unless $value =~ /^[-+]/;
     [ $label, $value ]
   } 
 ]

=back

For example, let's say we want to convert the string "x = 3 + 4" to the
following tokens:

  [ 'VAR', 'x' ]
  [ 'OP',  '=' ]
  [ 'NUM', 3   ]
  [ 'OP',  '+' ]
  [ 'NUM', 4   ]

One way to do this would be with the following code:

  my $text = 'x = 3 + 4';
  my @text = ($text);
  my $iter = sub { shift @text };
  
  my @input_tokens = (
      [ 'VAR',   qr/[[:alpha:]]+/    ],
      [ 'NUM',   qr/\d+/             ],
      [ 'OP',    qr/[+=]/            ],
      [ 'SPACE', qr/\s+/, sub { () } ],
  );
  
  my $lexer = make_lexer( $iter, @input_tokens );
  
  my @tokens;
  while ( my $token = $lexer->() ) {
      push @tokens, $token;
  }

C<@tokens> would contain the desired tokens.

Note that the order in which the input tokens are passed in might cause input
to be lexed in different ways, thus the order is significant (C</\w+/> might
slurp up numbers before C</\b\d+\b/> can read them).

=cut

sub make_lexer {
	my($input, @tokens) = @_;
	
	my $lexer_stream = make_lexer_stream($input, @tokens);
	return sub {
		my($peek) = @_;
		return ($peek||'') eq 'peek' ? head($lexer_stream) : drop($lexer_stream);
	};
}


sub make_lexer_stream {
	my($input, @tokens) = @_;
	$input = iterator_to_stream($input) if ref($input) eq 'CODE';	# convert to stream
	
	# variables for closure
	my $buf = ""; my $ahead = "";
	my %options;
	my $line_nr = 1;									# for FILE_POSITION option

	# extract all options in the order found in the list
	for (@tokens) {
		ref($_) eq 'HASH' or next;
		while (my($k, $v) = each %$_) {
			$options{$k} = $v;
		}
	}
	@tokens = grep { ref($_) eq 'ARRAY' } @tokens;		# extract only token definitions
	
	# build function chain to match each token, and regexp to match any token
	my $match_token_sub = sub { (undef, undef, ''); };	# return (found, token, matched_text)
	my $match_any_re;
	for (reverse @tokens) {
		my ($label, $regexp, $transform) = @$_;
		$transform ||= sub { [ $_[0] => $_[1] ] };
		
		my $previous_match_token_sub = $match_token_sub;
		$match_token_sub = 
			sub {
				if ( $buf =~ / \G ( (?> $regexp ) ) $ahead /gcx ) {
					my $matched = $1;
					my $token = $transform->( $label, $matched );
					return (1, $token, $matched);
				}
				else {
					return $previous_match_token_sub->();	# chain to previous match
				}
			};
		$match_any_re = $match_any_re ? 
							qr/(?> $regexp ) | $match_any_re /x : 
							qr/(?> $regexp )                 /x;
	}

	# return stream
	return iterator_to_stream 
		sub {
			my $no_match;
			for(;;) {
				# fill input buffer if needed
				while ($no_match || $buf =~ / \G \z /gcx) {
					# no match in previous loop or all buffer consumed
					
					# discard text already parsed
					pos($buf) and $buf = substr($buf, pos($buf));

					# get next chunk, check for end of input
					my $head = head($input);			
					if ( !defined($head) ||	ref($head) ) {
						# end of input or next is a token
						if ($buf eq '') {				# all string consumed
							return drop($input);		# return undef or token at head
						}
						else {
							# we have unparsed text here, return the un-parseable prefix
							my $ret;
							if ($buf =~ / $match_any_re /x) {
								# found a next token
								# special case for /\s*/ that matches at start of string, 
								# resulting in $` eq '' -> return and remove first char
								($ret, $buf) = $` eq '' ?
													(substr($buf,0,1), substr($buf,1)) :
													($`, $&.$');
								
							}
							else {
								# no next token
								($ret, $buf) = ($buf, '');
														# did not find next token, 
														# return whole string
							}
							$line_nr += ($ret =~ tr/\n/\n/)	if $options{FILE_POSITION};
							return $ret;				# return unparsed text as SCALAR
						}
					}
					
					# next chunk is text, append to scan buffer
					$buf .= drop($input);
					
					# return a token only if followed by something else, 
					# just in case one token is split across several chunks of input
					$head = head($input);
					$ahead = defined($head) && !ref($head) ?
								qr/ (?= .|\s ) /x :		# any char, if input not empty
								qr//;					# empty regexp at end of input
					
					$no_match = 0;
				}

				# match next token
				my($found, $token, $matched) = $match_token_sub->();
				if ($found) {
					if ($options{FILE_POSITION}) {
						push(@$token, $options{FILE_POSITION}, $line_nr) if $token;
						$line_nr += ($matched =~ tr/\n/\n/);
					}
					return $token if $token;
					next;								# discard token
				}
				else {
					$no_match++;
				}
			}
		};
}


=head2 file_lexer_stream

   my $file_stream = file_lexer_stream($file, @input_tokens);

The C<file_lexer_stream> function accepts a file name and a list of tokens to parse.
It returns a stream (see L<HOP::Stream>) of the tokens found in the given file.
Each token is returned as a four element array (see C<FILE_POSITION> option above):

 [ $label, $matched_text, $file_name, $line_nr ]

=cut

sub file_lexer_stream {
	my($file, @tokens) = @_;
	open(my $fh, $file) or die "Open $file: $!\n";
	return make_lexer_stream(sub {<$fh>}, @tokens, { FILE_POSITION => $file });
}

=head2 string_lexer

 my $lexer = string_lexer( $string, @tokens );

This function is identical to C<make_lexer>, but takes a string as the first
argument.  This is merely syntactic sugar for the common case where we have
our data in a string but don't want to create an iterator.  The following are
equivalent.

 my $lexer = string_lexer( $text, @input_tokens );

Versus:

 my @text  = ($text);
 my $iter  = sub { shift @text };
 my $lexer = make_lexer( $iter, @input_tokens );

=cut

sub string_lexer {
    my $text = shift;
    my @text = $text;
    return make_lexer( sub { shift @text }, @_ );
}


=head1 DEBUGGING

The following caveats (or pitfalls, if you prefer), should be kept in mind
while lexing data.

=over 4

=item * Unlexed data

The tokens returned by the lexer are array references.  If any data cannot be
lexed, it will be returned as a string, unchanged.

=item * Precedence

It's important to note that the order of the described tokens is important.
If you have keywords such as "while", "if", "unless", and so on, and any text
which matches C<qr/[[:word:]]+/> is considered a variable, the following fails:

  my @input_tokens = (
      [ 'VAR',     qr/[[:word:]]+/         ],
      [ 'KEYWORD', qr/(?:while|if|unless)/ ],
  );

This is because the potential keywords will be matched as C<VAR>.  To deal
with this, place the higher precedence tokens first:

  my @input_tokens = (
      [ 'KEYWORD', qr/(?:while|if|unless)/ ],
      [ 'VAR',     qr/[[:word:]]+/         ],
  );

=back

=head1 AUTHOR

Mark Jason Dominus.  Maintained by Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hop-lexer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HOP-Lexer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 FURTHER READING

See L<http://www.perl.com/pub/a/2006/01/05/parsing.html> for a detailed
article about using this module, along with a comprehensive example.

This has now been included in the distribution as L<HOP::Lexer::Article>.

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

1; # End of HOP::Lexer
