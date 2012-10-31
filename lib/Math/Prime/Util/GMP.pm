package Math::Prime::Util::GMP;
use strict;
use warnings;
use Carp qw/croak confess carp/;

BEGIN {
  $Math::Prime::Util::GMP::AUTHORITY = 'cpan:DANAJ';
  $Math::Prime::Util::GMP::VERSION = '0.04';
}

# parent is cleaner, and in the Perl 5.10.1 / 5.12.0 core, but not earlier.
# use parent qw( Exporter );
use base qw( Exporter );
our @EXPORT_OK = qw(
                     is_prime
                     is_prob_prime
                     is_strong_pseudoprime
                     is_strong_lucas_pseudoprime
                     primes
                     next_prime
                     prev_prime
                     trial_factor
                     prho_factor
                     pbrent_factor
                     pminus1_factor
                     holf_factor
                     squfof_factor
                     ecm_factor
                     factor
                     prime_count
                     primorial
                     pn_primorial
                     consecutive_integer_lcm
                   );
                   # Should add:
                   # nth_prime
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

BEGIN {
  eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $Math::Prime::Util::GMP::VERSION);
    1;
  } or do {
    die $@;
  }
}

sub _validate_positive_integer {
  my($n, $min, $max) = @_;
  croak "Parameter must be defined" if !defined $n;
  croak "Parameter '$n' must be a positive integer" if $n =~ tr/0123456789//c;
  croak "Parameter '$n' must be >= $min" if defined $min && $n < $min;
  croak "Parameter '$n' must be <= $max" if defined $max && $n > $max;
  1;
}


sub is_strong_pseudoprime {
  my($n, @bases) = @_;
  croak "No bases given to is_strong_pseudoprime" unless @bases;
  foreach my $base (@bases) {
    croak "Base $base is invalid" if $base < 2;
    return 0 unless _GMP_miller_rabin("$n", "$base");
  }
  1;
}

sub factor {
  my ($n) = @_;
  return ($n) if $n < 4;

  my @factors = sort {$a<=>$b} _GMP_factor($n);
  return @factors;
}

sub primes {
  my $optref = (ref $_[0] eq 'HASH')  ?  shift  :  {};
  croak "no parameters to primes" unless scalar @_ > 0;
  croak "too many parameters to primes" unless scalar @_ <= 2;
  my $low = (@_ == 2)  ?  shift  :  2;
  my $high = shift;
  my $sref = [];

  _validate_positive_integer($low);
  _validate_positive_integer($high);

  return $sref if ($low > $high) || ($high < 2);

  # Simple trial method for now.
  return _GMP_trial_primes($low, $high);

  # Trial primes without the XS code.  Works fine and is a lot easier than the
  # XS code (duh -- it's Perl).  But 30-40% slower, mostly due to lots of
  # string -> mpz -> string conversions and little memory allocations.
  #
  #my @primes;
  #my $curprime = is_prime($low)  ?  $low  :  next_prime($low);
  #while ($curprime <= $high) {
  #  push @primes, $curprime;
  #  $curprime = next_prime($curprime);
  #}
  #return \@primes;
}

1;

__END__


# ABSTRACT: Utilities related to prime numbers and factoring, using GMP

=pod

=encoding utf8


=head1 NAME

Math::Prime::Util::GMP - Utilities related to prime numbers and factoring, using GMP


=head1 VERSION

Version 0.04


=head1 SYNOPSIS

  use Math::Prime::Util::GMP ':all';
  my $n = "115792089237316195423570985008687907853269984665640564039457584007913129639937";

  # This doesn't impact the operation of the module at all, but does let you
  # enter big number arguments directly as well as enter (e.g.): 2**2048 + 1.
  use bigint;

  # is_prob_prime returns 0 for composite, 2 for prime, and 1 for maybe prime
  say "$n is ", qw(composite prob_prime def_prime)[is_prob_prime($n)];

  # is_prime currently is the same -- a BPSW test is used.
  say "$n is prime" if is_prime($n);

  # Run a series of Miller-Rabin tests
  say "$n is a prime or spsp-2/7/61" if is_strong_pseudoprime($n, 2, 7, 61);

  # See if $n is a strong Lucas-Selfridge pseudoprime
  say "$n is a prime or slpsp" if is_strong_lucas_pseudoprime($n);

  # Return array reference to primes in a range.
  my $aref = primes( 10 ** 200, 10 ** 200 + 10000 );

  $next = next_prime($n);    # next prime > n

  $prev = prev_prime($n);    # previous prime < n
  
  # Find prime factors of big numbers
  @factors = factor(5465610891074107968111136514192945634873647594456118359804135903459867604844945580205745718497);

  # Finer control over factoring.
  # These stop after finding one factor or exceeding their limit.
  #                               # optional arguments o1, o2, ...
  @factors = trial_factor($n);    # test up to o1
  @factors = prho_factor($n);     # no more than o1 rounds
  @factors = pbrent_factor($n);   # no more than o1 rounds
  @factors = pminus1_factor($n);  # o1 = smoothness limit, o2 = stage 2 limit
  @factors = holf_factor($n);     # no more than o1 rounds
  @factors = squfof_factor($n);   # no more than o1 rounds

=head1 DESCRIPTION

A set of utilities related to prime numbers, using GMP.  This includes
primality tests, getting primes in a range, and factoring.

While it certainly can be used directly, the main purpose of this module is
for L<Math::Prime::Util>.  That module will automatically load this if it is
installed, greatly speeding up many of its operations on big numbers.

Inputs and outputs for big numbers are via strings, so you do not need to
use a bigint package in your program.  However if you do use bigint, Perl
will automatically convert input for you, so you do not have to stringify
your numbers.  This output however will be returned as either Perl scalars
or strings.  L<Math::Prime::Util> tries to reconvert all strings back into
the callers bigint type if possible.


=head1 FUNCTIONS

=head2 is_prob_prime

  my $prob_prime = is_prob_prime($n);
  # Returns 0 (composite), 2 (prime), or 1 (probably prime)

Takes a positive number as input and returns back either 0 (composite),
2 (definitely prime), or 1 (probably prime).

For inputs below C<2^64> a deterministic test is performed, so the possible
return values are 0 (composite) or 2 (definitely prime).  The current
implementation uses a strong Baillie-PSW test, but later ones may use
a deterministic set of Miller-Rabin tests if that is faster for some inputs.

For inputs above C<2^64>, a probabilistic test is performed.  Only 0 (composite)
and 1 (probably prime) are returned.  There is a possibility that composites
may be returned marked prime, but since the test was published in 1980, not a
single BPSW pseudoprime has been found, so it is extremely likely to be prime.
While we believe (Pomerance 1984) that an infinite number of counterexamples
exist, there is a weak conjecture (Martin) that none exist under 10000 digits.


=head2 is_prime

  say "$n is prime!" if is_prime($n);

Takes a positive number as input and returns back either 0 (composite),
2 (definitely prime), or 1 (probably prime).  Composites will act exactly
like C<is_prob_prime>, as will numbers less than C<2^64>.  For numbers
larger than C<2^64>, some additional tests are performed on probable primes
to see if they can be proven by another means.

Currently a quick Pocklington test is applied to reasonable small (less
than 50 digit) numbers, which works surprisingly well without taking up
too much computational time.


=head2 is_strong_pseudoprime

  my $maybe_prime = is_strong_pseudoprime($n, 2);
  my $probably_prime = is_strong_pseudoprime($n, 2, 3, 5, 7, 11, 13, 17);

Takes a positive number as input and one or more bases.  Returns 1 if the
input is a prime or a strong pseudoprime to all of the bases, and 0 if not.

If 0 is returned, then the number really is a composite.  If 1 is returned,
then it is either a prime or a strong pseudoprime to all the given bases.
Given enough distinct bases, the chances become very, very strong that the
number is actually prime.

Both the input number and the bases may be big integers.  The bases must be
greater than 1, however they may be as large as desired.

This is usually used in combination with other tests to make either stronger
tests (e.g. the strong BPSW test) or deterministic results for numbers less
than some verified limit (e.g. Jaeschke showed in 1993 that no more than three
selected bases are required to give correct primality test results for any
32-bit number).  Given the small chances of passing multiple bases, there
are some math packages that just use multiple MR tests for primality testing.

Even numbers other than 2 will always return 0 (composite).  While the
algorithm works with even input, most sources define it only on odd input.
Returning composite for all non-2 even input makes the function match most
other implementations including L<Math::Primality>'s C<is_strong_pseudoprime>
function.


=head2 is_strong_lucas_pseudoprime

Takes a positive number as input, and returns 1 if the input is a strong
Lucas pseudoprime using the Selfridge method of choosing D, P, and Q (some
sources call this a strong Lucas-Selfridge pseudoprime).  This is one half
of the BPSW primality test (the Miller-Rabin strong pseudoprime test with
base 2 being the other half).


=head2 primes

  my $aref1 = primes( 1_000_000 );
  my $aref2 = primes( 2 ** 448, 2 ** 448 + 10000 );
  say join ",", @{primes( 2**2048, 2**2048 + 10000 )};

Returns all the primes between the lower and upper limits (inclusive), with
a lower limit of C<2> if none is given.

An array reference is returned (with large lists this is much faster and uses
less memory than returning an array directly).

The current implementation uses repeated calls to C<next_prime>.  This is not
as efficient as a sieve for large ranges, but also uses no additional memory
and is fast for very small ranges.


=head2 next_prime

  $n = next_prime($n);

Returns the next prime greater than the input number.


=head2 prev_prime

  $n = prev_prime($n);

Returns the prime smaller than the input number.  0 is returned if the
input is C<2> or lower.


=head2 primorial

  $p = primorial($n);

Given an unsigned integer argument, returns the product of the prime numbers
less than or equal to C<n>.  This is the
L<OEIS series A034386|http://oeis.org/A034386> definition of C<p#>.

=head2 pn_primorial

  $p = pn_primorial($n)

Given an unsigned integer argument, returns the product of the first C<n>
prime numbers.  This is the L<OEIS series A002110|http://oeis.org/A002110>
definition for C<p_n#>.

The two are related with the relationships:

  pn_primorial($n)  ==   primorial( nth_prime($n) )
  primorial($n)     ==   pn_primorial( prime_count($n) )

=head2 consecutive_integer_lcm

  $lcm = consecutive_integer_lcm($n);

Given an unsigned integer argument, returns the least common multiple of all
integers from 1 to C<n>.  This can be done by manipulation of the primes up
to C<n>, resulting in much faster and memory-friendly results than using
n factorial.


=head2 factor

  @factors = factor(640552686568398413516426919223357728279912327120302109778516984973296910867431808451611740398561987580967216226094312377767778241368426651540749005659);
  # Returns an array of 11 factors

Returns a list of prime factors of a positive number, in numerical order.  The
special cases of C<n = 0> and C<n = 1> will return C<n>.

The current algorithm uses trial division, then while the number is composite
it runs a sequence of factoring tests, including small runs of Pollard's Rho,
perfect power detection, small ECM runs, Pollard's P-1 with various smoothness
and stage settings, longer runs of Pollard's Rho using Brent's algorithm,
a quick check with Hart's OLF, a long run with ECM, and will finally give up.

Certainly improvements could be designed for this algorithm (suggestions are
welcome).  Most importantly, adding MPQS/SIQS would make a huge difference
with larger numbers.  These are non-trivial (though feasible) methods.

In practice, this factors most 26-digit semiprimes in under a second.  Cracking
14-digit prime factors from large numbers takes about 5 seconds each (Pari
takes about 1 second, and yafu about 0.3 seconds).  20-digit factors are
practical but take a long time compared to real factoring programs.  Beyond
20-digits will take inordinately long.  Note that these are the size of the
smallest factor, not the size of the input number, as shown by the example.


=head2 trial_factor

  my @factors = trial_factor($n);
  my @factors = trial_factor($n, 1000);

Given a positive number input, tries to discover a factor using trial division.
The resulting array will contain either two factors (it succeeded) or the
original number (no factor was found).  In either case, multiplying @factors
yields the original input.  An optional divisor limit may be given as the
second parameter.  Factoring will stop when the input is a prime, one factor
is found, or the input has been tested for divisibility with all primes less
than or equal to the limit.  If no limit is given, then C<2**31-1> will be used.

This is a good and fast initial test, and will be very fast for small numbers
(e.g. under 1 million).  It becomes unreasonably slow in the general case as
the input size increases.


=head2 prho_factor

  my @factors = prho_factor($n);
  my @factors = prho_factor($n, 100_000_000);

Given a positive number input, tries to discover a factor using Pollard's Rho
method.  The resulting array will contain either two factors (it succeeded)
or the original number (no factor was found).  In either case, multiplying
@factors yields the original input.  An optional number of rounds may be
given as the second parameter.  Factoring will stop when the input is a prime,
one factor has been found, or the number of rounds has been exceeded.

This is the Pollard Rho method with C<f = x^2 + 3> and default rounds 64M.  It
is very good at finding small factors.


=head2 pbrent_factor

  my @factors = pbrent_factor($n);
  my @factors = pbrent_factor($n, 100_000_000);

Given a positive number input, tries to discover a factor using Pollard's Rho
method with Brent's algorithm.  The resulting array will contain either two
factors (it succeeded) or the original number (no factor was found).  In
either case, multiplying @factors yields the original input.  An optional
number of rounds may be given as the second parameter.  Factoring will stop
when the input is a prime, one factor has been found, or the number of
rounds has been exceeded.

This is the Pollard Rho method using Brent's modified cycle detection and
backtracking.  It is essentially Algorithm P''2 from Brent (1980).  Parameters
used are C<f = x^2 + 3> and default rounds 64M.  It is very good at finding
small factors.


=head2 pminus1_factor

  my @factors = pminus1_factor($n);

  # Ramp to to B1=10M, with second stages automatically done
  my @factors = pminus1_factor($n, 10_000_000);

  # Run p-1 with B1 = 10M, B2 = 100M.  No ramping.
  my @factors = pminus1_factor($n, 10_000_000, 100_000_000);

Given a positive number input, tries to discover a factor using Pollard's
C<p-1> method.  The resulting array will contain either two factors (it
succeeded) or the original number (no factor was found).  In either case,
multiplying @factors yields the original input.  An optional maximum
smoothness factor (B1) may be given as the second parameter in which case the
algorithm will ramp up to that smoothness factor, also running a second stage.
If a third parameter (B2) is given, then no ramping happens -- just a first
stage using the given B1 smoothness followed by a second stage to the B2
smoothness.  Factoring will stop when the input is a prime, one factor has
been found, or the algorithm fails to find a factor with the given smoothness.

This is Pollard's C<p-1> method using a default smoothness of 1M and a
second stage of C<B2 = 20 * B1>.  It can quickly find a factor C<p> of the input
C<n> if the number C<p-1> factors into small primes.  For example
C<n = 22095311209999409685885162322219> has the factor C<p = 3916587618943361>,
where C<p-1 = 2^7 * 5 * 47 * 59 * 3137 * 703499>, so this method will find
a factor in the first stage if C<B1 E<gt>= 703499> or in the second stage if
C<B2 E<gt>= 703499>.

The implementation is written from scratch using the basic algorithm including
a second stage as described in Montgomery 1987.  It is faster than most simple
implementations I have seen (many of which are written assuming native
precision inputs), but far slower than Ben Buhrow's code used in earlier
versions of L<yafu|http://sourceforge.net/projects/yafu/>, and nowhere close
to the speed of the version included with modern GMP-ECM (as much as 1000x
slower).



=head2 holf_factor

  my @factors = holf_factor($n);
  my @factors = holf_factor($n, 100_000_000);

Given a positive number input, tries to discover a factor using Hart's OLF
method.  The resulting array will contain either two factors (it succeeded)
or the original number (no factor was found).  In either case, multiplying
@factors yields the original input.  An optional number of rounds may be
given as the second parameter.  Factoring will stop when the input is a
prime, one factor has been found, or the number of rounds has been exceeded.

This is Hart's One Line Factorization method, which is a variant of Fermat's
algorithm.  A premultiplier of 480 is used.  It is very good at factoring
numbers that are close to perfect squares, or small numbers.  Very naive
methods of picking RSA parameters sometimes yield numbers in this form, so
it can be useful to run this a few rounds to see.  For example, the number:

  18548676741817250104151622545580576823736636896432849057 \
  10984160646722888555430591384041316374473729421512365598 \
  29709849969346650897776687202384767704706338162219624578 \
  777915220190863619885201763980069247978050169295918863

was proposed by someone as an RSA key.  It is indeed composed of two distinct
prime numbers of similar bit length.  Most factoring methods will take a
B<very> long time to break this.  However one factor is almost exactly 5x
larger than the other, allowing HOLF to factor this 222-digit semiprime in
only a few milliseconds.


=head2 squfof_factor

  my @factors = squfof_factor($n);
  my @factors = squfof_factor($n, 100_000_000);

Given a positive number input, tries to discover a factor using Shanks'
square forms factorization method (usually known as SQUFOF).  The resulting
array will contain either two factors (it succeeded) or the original number
(no factor was found).  In either case, multiplying @factors yields the
original input.  An optional number of rounds may be given as the second
parameter.  Factoring will stop when the input is a prime, one factor has
been found, or the number of rounds has been exceeded.

This is Daniel Shanks' SQUFOF (square forms factorization) algorithm.  The
particular implementation is a non-racing multiple multiplier version, based
on code ideas of Ben Buhrow and Jason Papadopoulos as well as many others.
SQUFOF is often the preferred method for small numbers, and L<Math::Prime::Util>
as well as many other packages use it was the default method for native size
(e.g. 32-bit or 64-bit) numbers after trial division.  The GMP version used
in this module will work for larger values, but my testing is showing that it
is not faster than the C<prho> and C<pbrent> methods in general.


=head2 ecm_factor

  my @factors = ecm_factor($n);
  my @factors = ecm_factor($n, 12500);
  my @factors = ecm_factor($n, 12500, 10);

Given a positive number input, tries to discover a factor using ECM.  The
resulting array will contain either two factors (it succeeded) or the original
number (no factor was found).  In either case, multiplying @factors yields the
original input.  An optional maximum smoothness may be given as the second
parameter, which relates to the size of factor to search for.  An optional
third parameter indicates the number of random curves to use at each
smoothness value being searched.

This is a straightforward implementation of Hendrik Lenstra's elliptic curve
factoring method, usually referred to as ECM.  Its implementation is textbook,
with no substantial optimizations done.  It uses a single stage, affine
coordinates, binary ladder multiplication, and simple initialization.  The
list of enhancements that can be made is numerous, and it will be much, much
slower than GMP-ECM.  However, it uses simple GMP and extends the useful
factoring range of this module.


=head1 SEE ALSO

=over 4

=item  L<Math::Prime::Util>.
Has many more functions, lots of good code for dealing with native-precision
arguments (including much faster primes using sieves), and will use this
module behind the scenes when needed for big numbers.

=item  L<Math::Primality> (version 0.07)
A Perl module with support for the strong Miller-Rabin test, strong
Lucas-Selfridge test, the BPSW test, next_prime / prev_prime, and
prime_count.  It uses L<Math::GMPz> to do all the calculations, so is
faster than pure Perl bignums, but a little slower than XS+GMP.  The
prime_count function is only usable for very small inputs (it is many
thousands of times slower than L<Math::Prime::Util>), but the other
functions are reasonable, though a little slower than this module.
If you use large numbers, make sure to use version 0.05 or newer.

=item L<yafu|http://sourceforge.net/projects/yafu/>, 
L<msieve|http://sourceforge.net/projects/msieve/>,
L<gmp-ecm|http://ecm.gforge.inria.fr/>
Good general purpose factoring utilities.  These will be faster than this
module, and B<much> faster as the factor increases in size.

=back


=head1 REFERENCES

=over 4

=item Robert Baillie and Samuel S. Wagstaff, Jr., "Lucas Pseudoprimes", Mathematics of Computation, v35 n152, October 1980, pp 1391-1417.  L<http://mpqs.free.fr/LucasPseudoprimes.pdf>

=item Richard P. Brent, "An improved Monte Carlo factorization algorithm", BIT 20, 1980, pp. 176-184.  L<http://www.cs.ox.ac.uk/people/richard.brent/pd/rpb051i.pdf>

=item Richard P. Brent, "Parallel Algorithms for Integer Factorisation", in Number Theory and Cryptography, Cambridge University Press, 1990, pp 26-37.  L<http://www.cs.ox.ac.uk/people/richard.brent/pd/rpb115.pdf>

=item Richard P. Brent, "Some Parallel Algorithms for Integer Factorisation", in Proc. Third Australian Supercomputer Conference, 1999. (Note: there are multiple versions of this paper)  L<http://www.cs.ox.ac.uk/people/richard.brent/pd/rpb193.pdf>

=item William B. Hart, "A One Line Factoring Algorithm", preprint.  L<http://wstein.org/home/wstein/www/home/wbhart/onelinefactor.pdf>

=item Daniel Shanks, "SQUFOF notes", unpublished notes, transcribed by Stephen McMath.  L<http://www.usna.edu/Users/math/wdj/mcmath/shanks_squfof.pdf>

=item Jason E. Gower and Samuel S. Wagstaff, Jr, "Square Form Factorization", Mathematics of Computation, v77, 2008, pages 551-588.  L<http://homes.cerias.purdue.edu/~ssw/squfof.pdf>

=item Peter L. Montgomery, "Speeding the Pollard and Elliptic Curve Methods of Factorization", Mathematics of Computation, v48, n177, Jan 1987, pp 243-264.  L<http://www.ams.org/journals/mcom/1987-48-177/S0025-5718-1987-0866113-7/>

=back


=head1 AUTHORS

Dana Jacobsen E<lt>dana@acm.orgE<gt>


=head1 ACKNOWLEDGEMENTS

Obviously none of this would be possible without the mathematicians who
created and published their work.  Eratosthenes, Gauss, Euler, Riemann,
Fermat, Lucas, Baillie, Pollard, Brent, Montgomery, Shanks, Hart, Wagstaff,
Dixon, Pomerance, A.K Lenstra, H. W. Lenstra Jr., Knuth, etc.

The GNU GMP team, whose product allows me to concentrate on coding high-level
algorithms and not worry about any of the details of how modular exponentiation
and the like happen, and still get decent performance for my purposes.

Ben Buhrows and Jason Papadopoulos deserve special mention for their open
source factoring tools, which are both readable and fast.  In particular I am
leveraging their SQUFOF work in the current implementation.  They are a huge
resource to the community.

Jonathan Leto and Bob Kuo, who wrote and distributed the L<Math::Primality>
module on CPAN.  Their implementation of BPSW provided the motivation I needed
to get it done in this module and L<Math::Prime::Util>.  I also used their
module quite a bit for testing against.


=head1 COPYRIGHT

Copyright 2011-2012 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
