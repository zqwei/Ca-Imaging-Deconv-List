function y = fn_add(u,v,varargin)
% function y = fn_add(u,v,...)
%---
% tool to add matrices and vectors
% ex: y = fn_add(rand(4,5),(1:4)')
%     y = fn_add(1:5,(1:4)')
%
% See also fn_mult, fn_subtract, fn_div, fn_eq

% Thomas Deneux
% Copyright 2002-2017

y = bsxfun(@plus,u,v);
for i=1:length(varargin), y = bsxfun(@plus,y,varargin{i}); end
    
