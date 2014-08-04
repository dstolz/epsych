/* HIGH ACCURACY TIMER
 *
 * compile command (needs windows SDK):
 * mex -O hat.c
 *
 * Ivo Houtzager
 */

#include "windows.h"
#include "mex.h"

__inline void hightimer( double *hTimePtr )
{
    HANDLE hCurrentProcess = GetCurrentProcess();
    DWORD dwProcessAffinity;
    DWORD dwSystemAffinity;    
    LARGE_INTEGER frequency, counter;
    double sec_per_tick, total_ticks;
    
    /* force thread on first cpu */
    GetProcessAffinityMask(hCurrentProcess,&dwProcessAffinity,&dwSystemAffinity);
    SetProcessAffinityMask(hCurrentProcess, 1);
    
	/* retrieves the frequency of the high-resolution performance counter */
    QueryPerformanceFrequency(&frequency);
    
    /* retrieves the current value of the high-resolution performance counter */
    QueryPerformanceCounter(&counter);
    
     /* reset thread */
    SetProcessAffinityMask(hCurrentProcess,dwProcessAffinity);

	/* time in seconds */
    sec_per_tick = (double)1/(double)frequency.QuadPart;
    total_ticks = (double)counter.QuadPart;  
    *hTimePtr = sec_per_tick * total_ticks;

    return;
}	/* end hightimer */


void mexFunction( int nlhs, mxArray *plhs[], int nrhs,
                  const mxArray *prhs[] )
{
    double hTime;

    /* check for proper number of arguments */
    if ( nrhs != 0 ) {
        mexErrMsgTxt( "No arguments required." );
    }

    /* do the actual computations in a subroutine */
	hightimer( &hTime );

	/* create a matrix for the return argument */
    plhs[0] = mxCreateDoubleScalar( hTime );

    return;
}	/* end mexFunction */