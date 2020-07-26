function xround = roundto(x, d)
if nargin == 1; d = 2; end
xround = round(x/10^(-d))*10^(-d);