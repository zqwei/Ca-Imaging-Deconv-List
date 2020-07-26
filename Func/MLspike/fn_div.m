function y=fn_div(u,v)
% function y=fn_div(u,v)
%----
% tool to divide a matrix row- or column-wise
% ex: y = fn_div(rand(3,4),(1:3)')
%     y = fn_div(rand(5,2,5),shiftdim(ones(5,1),-2))
%
% See also fn_mult, fn_add, fn_subtract

% Thomas Deneux
% Copyright 2012-2017

y = bsxfun(@rdivide,u,v);

    