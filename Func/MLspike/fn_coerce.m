function y = fn_coerce(x,m,M)
% function y = fn_coerce(x,m,M)
% function y = fn_coerce(x,[m M])
%---
% y = min(max(x,m),M);

% Thomas Deneux
% Copyright 2002-2017

if nargin==2,
    M = m(2);
    m = m(1);
end
y = min(max(x,m),M);
