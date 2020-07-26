function x = third(x)
% function x = third(x)
%---
% reshape x to a third-dimension vector
%
% See also column, row, matrix

% Thomas Deneux
% Copyright 2015-2017

x = shiftdim(x(:),-2);
