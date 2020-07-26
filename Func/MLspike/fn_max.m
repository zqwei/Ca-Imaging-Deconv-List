function [m I] = fn_max(a)
% function [m I] = fn_max(a)
%---
% find the global max in an array, and give its coordinates
%
% See also fn_min

% Thomas Deneux
% Copyright 2005-2017

if nargin==0, help fn_min, return, end

[m i] = max(a(:));
i = i-1;
s = size(a);
for k=1:length(s)
    I(k) = mod(i,s(k))+1;
    i = floor(i/s(k));
end
