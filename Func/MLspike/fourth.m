function x = fourth(x)
%---
% reshape x to a fourth-dimension vector
%
% See also column, row, third, matrix

% Thomas Deneux
% Copyright 2015-2017

x = shiftdim(x(:),-3);
