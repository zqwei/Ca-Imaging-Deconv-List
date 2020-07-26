function n = fn_itemlengths(c)
% function n = fn_itemlengths(c)
%---
% returns an array of same size as cell array c, containing the length of
% each of its elements

% Thomas Deneux
% Copyright 2015-2017

n = zeros(size(c));
for i=1:numel(c), n(i) = length(c{i}); end
