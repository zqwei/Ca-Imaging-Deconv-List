function m = nmedian(x,dim)
% function y = nmedian(x,dim)
%---
% returns median while ignoring NaNs
%
% see also nmean, nstd, nste

% Thomas Deneux
% Copyright 2015-2017

% dimension on which to apply median
sz = size(x);
if nargin<2
    dim = find(sz ~= 1,1);
    if isempty(dim), dim = 1; end
end
szout = sz; szout(dim) = 1;

% work on 1st dimension
x = fn_reshapepermute(x,{dim setdiff(1:length(sz),dim)});
sz2 = size(x);

% sort values
y = sort(x,1);

% handle NaNs
nok = sum(~isnan(x),1);
nok(nok==0) = 1;    % the first value will be picked-up, as if it was non-NaN 
midx = (nok+1)/2;   % can be integer or integer+0.5, in which case the mean of the two adjacent values will be computed

% get median!
idx = sub2ind(sz2,[floor(midx); ceil(midx)],[1:sz2(2); 1:sz2(2)]);
m = mean(y(idx),1);

% final reshape
m = reshape(m,szout);
