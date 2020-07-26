function y = nstd(x,w,dim)
% function y = nstd(x,w,dim)
%---
% returns standard deviation while ignoring NaNs
%
% see also nmean, nste

% The MathWorks, Inc.
% Copyright 1993-2006
% Thomas Deneux
% Copyright 2015-2017


% COMPUTE NANVAR
if nargin < 2 || isempty(w), w = 0; end

sz = size(x);
if nargin < 3 || isempty(dim)
    % The output size for [] is a special case when DIM is not given.
    if isequal(x,[]), y = NaN(class(x)); return; end

    % Figure out which dimension sum will work along.
    dim = find(sz ~= 1, 1);
    if isempty(dim), dim = 1; end
elseif dim > length(sz)
    sz(end+1:dim) = 1;
end

% Count up non-NaNs.
n = sum(~isnan(x),dim);

if w == 0
    % The unbiased estimator: divide by (n-1).  Can't do this when
    % n == 0 or 1, so n==1 => we'll return zeros
    denom = max(n-1, 1);
elseif w == 1
    % The biased estimator: divide by n.
    denom = n; % n==1 => we'll return zeros
else
    error argument
end
denom(n==0) = NaN; % Make all NaNs return NaN, without a divideByZero warning

x0 = fn_subtract(x,nmean(x,dim));
y = nsum(abs(x0).^2, dim) ./ denom; % abs guarantees a real result

% TAKE THE SQUARE ROOT
y = sqrt(y);
