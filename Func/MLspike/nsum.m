function y = nsum(x,dim)
% function y = nsum(x,dim)
%---
% returns sum while ignoring NaNs
%
% see also nmean

% The MathWorks, Inc.
% Copyright 1993-2004
% Thomas Deneux
% Copyright 2015-2017


% Find NaNs and set them to zero.  Then sum up non-NaNs.  Cols of all NaNs
% will return zero.
x(isnan(x)) = 0;
if nargin == 1 % let sum figure out which dimension to work along
    y = sum(x);
else           % work along the explicitly given dimension
    y = sum(x,dim);
end
