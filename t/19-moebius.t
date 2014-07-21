#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Math::Prime::Util::GMP qw/moebius liouville totient jordan_totient
                              exp_mangoldt/;
my $extra = defined $ENV{EXTENDED_TESTING} && $ENV{EXTENDED_TESTING};

my @moeb_vals = (qw/ 1 -1 -1 0 -1 1 -1 0 0 1 -1 0 -1 1 1 0 -1 0 -1 0 /);

my %totients = (
     123456 => 41088,
     123457 => 123456,
  123456789 => 82260072,
);
my @A000010 = (0,1,1,2,2,4,2,6,4,6,4,10,4,12,6,8,8,16,6,18,8,12,10,22,8,20,12,18,12,28,8,30,16,20,16,24,12,36,18,24,16,40,12,42,20,24,22,46,16,42,20,32,24,52,18,40,24,36,28,58,16,60,30,36,32,48,20,66,32,44);
#@totients{0..$#A000010} = @A000010;

my @A001615 = (1,3,4,6,6,12,8,12,12,18,12,24,14,24,24,24,18,36,20,36,32,36,24,48,30,42,36,48,30,72,32,48,48,54,48,72,38,60,56,72,42,96,44,72,72,72,48,96,56,90,72,84,54,108,72,96,80,90,60,144,62,96,96,96,84,144,68,108,96);

my %jordan_totients = (
  # A000010
  1 => [1, 1, 2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12, 6, 8, 8, 16, 6, 18, 8, 12, 10, 22, 8, 20, 12, 18, 12, 28, 8, 30, 16, 20, 16, 24, 12, 36, 18, 24, 16, 40, 12, 42, 20, 24, 22, 46, 16, 42, 20, 32, 24, 52, 18, 40, 24, 36, 28, 58, 16, 60, 30, 36, 32, 48, 20, 66, 32, 44],
  # A007434
  2 => [1, 3, 8, 12, 24, 24, 48, 48, 72, 72, 120, 96, 168, 144, 192, 192, 288, 216, 360, 288, 384, 360, 528, 384, 600, 504, 648, 576, 840, 576, 960, 768, 960, 864, 1152, 864, 1368, 1080, 1344, 1152, 1680, 1152, 1848, 1440, 1728, 1584, 2208, 1536],
  # A059376
  3 => [1, 7, 26, 56, 124, 182, 342, 448, 702, 868, 1330, 1456, 2196, 2394, 3224, 3584, 4912, 4914, 6858, 6944, 8892, 9310, 12166, 11648, 15500, 15372, 18954, 19152, 24388, 22568, 29790, 28672, 34580, 34384, 42408, 39312, 50652, 48006, 57096],
  # A059377
  4 => [1, 15, 80, 240, 624, 1200, 2400, 3840, 6480, 9360, 14640, 19200, 28560, 36000, 49920, 61440, 83520, 97200, 130320, 149760, 192000, 219600, 279840, 307200, 390000, 428400, 524880, 576000, 707280, 748800, 923520, 983040, 1171200],
  # A059378
  5 => [1, 31, 242, 992, 3124, 7502, 16806, 31744, 58806, 96844, 161050, 240064, 371292, 520986, 756008, 1015808, 1419856, 1822986, 2476098, 3099008, 4067052, 4992550, 6436342, 7682048, 9762500, 11510052, 14289858, 16671552, 20511148, 23436248, 28629150, 32505856, 38974100, 44015536, 52501944, 58335552, 69343956, 76759038, 89852664, 99168256, 115856200, 126078612, 147008442, 159761600, 183709944, 199526602, 229345006, 245825536, 282458442, 302637500, 343605152, 368321664],
  # A069091
  6 => [1, 63, 728, 4032, 15624, 45864, 117648, 258048, 530712, 984312, 1771560, 2935296, 4826808, 7411824, 11374272, 16515072, 24137568, 33434856, 47045880, 62995968, 85647744, 111608280, 148035888, 187858944, 244125000, 304088904, 386889048],
  # A069092
  7 => [1, 127, 2186, 16256, 78124, 277622, 823542, 2080768, 4780782, 9921748, 19487170, 35535616, 62748516, 104589834, 170779064, 266338304, 410338672, 607159314, 893871738, 1269983744, 1800262812, 2474870590, 3404825446],
);

my @liouville_pos = (qw/24 51 94 183 294 629 1488 3684 8006 8510 32539 57240
   103138 238565 444456 820134 1185666 3960407 4429677 13719505 29191963
   57736144 134185856 262306569 324235872 563441153 1686170713 2489885844/);
my @liouville_neg = (qw/23 47 113 163 378 942 1669 2808 8029 9819 23863 39712
   87352 210421 363671 562894 1839723 3504755 7456642 14807115 22469612
   49080461 132842464 146060791 279256445 802149183 1243577750 3639860654/);
push @liouville_pos, (qw/1260238066729040 10095256575169232896/);
push @liouville_neg, (qw/1807253903626380 12063177829788352512/);

my %mangoldt = (
-13 => 1,
  0 => 1,
  1 => 1,
  2 => 2,
  3 => 3,
  4 => 2,
  5 => 5,
  6 => 1,
  7 => 7,
  8 => 2,
  9 => 3,
 10 => 1,
 11 => 11,
 25 => 5,
 27 => 3,
 399981 => 1,
 399982 => 1,
 399983 => 399983,
 823543 => 7,
 83521 => 17,
 130321 => 19,
);


plan tests => 1
            + 1 # moeb_vals
            + 1 + scalar(keys %totients)
            + scalar(keys %jordan_totients)
            + scalar(@liouville_pos) + scalar(@liouville_neg)
            + scalar(keys %mangoldt);


###### moebius
ok(!eval { moebius(0); }, "moebius(0)");
{
  my @moebius = map { moebius($_) } (1 .. scalar @moeb_vals);
  is_deeply( \@moebius, \@moeb_vals, "moebius 1 .. " . scalar @moeb_vals );
}

###### totient
{
  my @phi = map { totient($_) } (0 .. $#A000010);
  is_deeply( \@phi, \@A000010, "totient 0 .. $#A000010" );
}
while (my($n, $phi) = each (%totients)) {
  is( totient($n), $phi, "euler_phi($n) == $phi" );
}

###### Jordan Totient
while (my($k, $tref) = each (%jordan_totients)) {
  my @tlist = map { jordan_totient($k, $_) } 1 .. scalar @$tref;
  is_deeply( \@tlist, $tref, "Jordan's Totient J_$k" );
}

###### liouville
foreach my $i (@liouville_pos) {
  is( liouville($i),  1, "liouville($i) = 1" );
}
foreach my $i (@liouville_neg) {
  is( liouville($i), -1, "liouville($i) = -1" );
}

###### Exponential of von Mangoldt
while (my($n, $em) = each (%mangoldt)) {
  is( exp_mangoldt($n), $em, "exp_mangoldt($n) == $em" );
}
