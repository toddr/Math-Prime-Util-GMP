#ifndef MPU_FACTOR_H
#define MPU_FACTOR_H

#include <gmp.h>
#include "ptypes.h"

extern int factor(mpz_t n, mpz_t* factors[], int* exponents[]);
extern void clear_factors(int nfactors, mpz_t* pfactors[], int* pexponents[]);

extern int moebius(mpz_t n);
extern int liouville(mpz_t n);

#endif
