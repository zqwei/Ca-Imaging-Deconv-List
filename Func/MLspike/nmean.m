function m = nmean(x,dim)
% function y = nmean(x,dim)
%---
% returns average while ignoring NaNs
%
% see also nsum, nstd, nste, nrms, nmedian

% The MathWorks, Inc.
% Copyright 1993-2004
% Thomas Deneux
% Copyright 2015-2017


% Find NaNs and set them to zero
nans = isnan(x);
x(nans) = 0;

if nargin == 1 % let sum deal with figuring out which dimension to use
    % Count up non-NaNs.
    n = sum(~nans);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x) ./ n;
else
    % Count up non-NaNs.
    n = sum(~nans,dim);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x,dim) ./ n;
end

