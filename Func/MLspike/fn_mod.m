function x = fn_mod(x,y)
% function x = fn_mod(x,y)
%---
% returns a value between 1 and y equal to x [mod y]
% y must be a positive integer

% Thomas Deneux
% Copyright 2008-2017

if ~mod(y,0) || y<=0, error('y must be a positive integer'), end
x = 1 + mod(x-1,y);

