/* Purpose:


     Procedure upstat accumulates the sample mean and sample
     variance.   For example:

     N = 0
     DO FOR I = 1, IMAX
        CALL UPSTAT2( X(I), SMEAN, SVAR, N )
     END FOR

     On output SMEAN is the average, and SVAR is the sample variance.

     SMEAN = sum_{I=1}^{IMAX} X(I)
             ---------------------
                     IMAX

     SVAR  = sum_{I=1}^{IMAX} (X(I) - SMEAN)^2
             ---------------------------------
                   ( IMAX-1 )

     N     = IMAX

     If N = 0 on input, then on output SMEAN = X, SVAR = 0, and N = 1

*/

#include "filter.h"
#include "filter_prototype.h"

static const char SccsId[] = "@(#)   upstats.c   1.5   07/26/13";

void upstats ( double x, double gain, simple_stats *ss )

{
   double np1;
   double nm1;
   double delta;

   if ( ss->n == 0 ) {
      ss->n    = 1;
      ss->ave  = x; 
      ss->svar = 0.0;
      ss->max  = x;
      ss->min  = x;
      ss->x_smooth = x;
      ss->sum_sqr = x*x;
   } else {
      delta = x - ss->ave;
      np1 = ss->n + 1; 
      nm1 = ss->n - 1;
      ss->ave = delta/np1 + ss->ave;
      ss->svar = nm1/(ss->n) * (ss->svar) + delta*delta/np1;
      ss->n = (int) np1;
      if ( x > ss->max ) ss->max = x;
      if ( x < ss->min ) ss->min = x;
      ss->x_smooth = ss->x_smooth + 1.0/gain*( x - ss->x_smooth );
      ss->sum_sqr += x*x;
   }
   return;
}
