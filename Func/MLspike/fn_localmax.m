function i = fn_localmax(x)
% function i = fn_localmax(x)
%---
% find local maxima in vector x (cannot be extremities)

% Thomas Deneux
% Copyright 2004-2017

if nargin==0, help fn_localmax, return, end

if ~isvector(x), error('input must be a vector'), end

nx = length(x);
d1 = (diff(x)>0);
d2 = (diff(x)<0);
i = 1 + find(d1(1:nx-2)&d2(2:nx-1));
if isempty(i), i=[]; end



