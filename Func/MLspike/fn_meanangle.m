function phi = fn_meanangle(angles)
% function phi = fn_meanangle(angles)

% Thomas Deneux
% Copyright 2011-2017

if ~isvector(angles), error('''angles'' must be a vector'), end
z = sum(exp(1i*angles));
phi = angle(z);