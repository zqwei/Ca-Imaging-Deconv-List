function b=fn_isuniform(x,dim)
% function b=fn_isuniform(x,dim)
%---
% check whether all array elements in dimension(s) dim are the same

% Thomas Deneux
% Copyright 2015-2017

% put together dimensions
s = size(x); s(end+1:max(dim))=1;
perm = [1:dim(1) dim(2:end) setdiff(dim(1)+1:ndims(x),dim(2:end))];
x = permute(x,perm);
s(dim(1)) = prod(s(dim));
s(dim(2:end)) = 1;
x = reshape(x,s);

% check uniformity
b = ~any(diff(x,1,dim(1)),dim(1));

