function b = fn_isemptyc(varargin)
% function b = fn_isemptyc(c)
% function b = fn_isemptyc(x1,x2,x3,...)
%---
% returns an array of logicals of the same size as cell array c indicating
% which elements of c are empty
%
% See also fn_find, fn_map, fn_itemlengths

% Thomas Deneux
% Copyright 2011-2017

if nargin==0, help fn_isemptyc, return, end

if nargin==1
    c = varargin{1};
else
    c = varargin;
end

b = false(size(c));
for k=1:numel(c), b(k) = isempty(c{k}); end
