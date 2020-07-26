function y = nste(x,dim)
% function y = nste(x,dim)
%---
% returns standard error while ignoring NaNs
% returns NaNs where there is only one data point
%
% see also nmean, nstd

% The MathWorks, Inc.
% Copyright 1993-2006
% Thomas Deneux
% Copyright 2015-2017

% Input
sz = size(x);
if nargin < 2 || isempty(dim)
    % The output size for [] is a special case when DIM is not given.
    if isequal(x,[]), y = NaN(class(x)); return; end

    % Figure out which dimension sum will work along.
    dim = find(sz ~= 1, 1);
    if isempty(dim), dim = 1; end
elseif dim > length(sz)
    sz(end+1:dim) = 1;
end

% Compute variance
n = sum(~isnan(x),dim);
denom = max(n-1, 0); % STE will return NaNs where there is only one data point
denom(n==0) = NaN; % Make all NaNs return NaN, without a divideByZero warning

x0 = fn_subtract(x,nmean(x,dim));
y = nsum(abs(x0).^2, dim) ./ denom; % abs guarantees a real result

% Square root to get standard deviation
y = sqrt(y);

% Devide by square root of n to get standard error
y = y ./ sqrt(n);
