#include <mat.h>
#include <mex.h>

void checkargs(int nargout, int nargin, int minout, int maxout, int minin, int maxin){
	if (nargin<minin || nargin>maxin)
		mexErrMsgTxt("Wrong number of input arguments");
	if (nargout<minout || nargout>maxout)
		mexErrMsgTxt("Wrong number of output arguments");
}

void mexFunction( int nargout, mxArray* pargout[], int nargin, const mxArray* pargin[] ) 
{
  	char s[10]; 
    checkargs(nargout,nargin,0,1,1,1);
    sprintf(s,"%X",(mxGetPr(pargin[0])));
    pargout[0] = mxCreateString(s);
}

