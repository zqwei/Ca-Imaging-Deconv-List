function y=fn_subtract(u,v)
% function y=fn_subtract(u,v)
%----
% tool to subtract a matrix row- or column-wise
% ex: y = fn_subtract(rand(3,4),(1:3)')
%     y = fn_subtract(rand(5,2,5),shiftdim(ones(5,1),-2))
%
% See also fn_add, fn_mult, fn_div

% Thomas Deneux
% Copyright 2012-2017

y = bsxfun(@minus,u,v);


    