function b = fn_sizecompare(s1,s2)
% function b = fn_sizecompare(s1,s2)
%---
% compare size vectors by first making them the same length by padding with
% 1s; for example:
% fn_sizecompare(3,[3 1]) returns true
% fn_sizecompare(3,[1 3]) returns false

% Thomas Deneux
% Copyright 2005-2017

l1 = length(s1);
l2 = length(s2);
if l1>l2
    s2(l2+1:l1) = 1;
elseif l2>l1
    s1(l1+1:l2) = 1;
end

b = all(s1(:)==s2(:));