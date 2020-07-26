function pr = fn_getPr(var)
% function pr = fn_getPr(var)
%---
% This MEX-file returns the pointer to the data of variable 'var'. 
% This can be very useful to understand when two Matlab variables having
% the same content do share the same pointer or not, i.e. when is the data
% of these variables shared or duplicated. Ensuring that data of large
% arrays is shared rather than duplicated will ensure efficient memory
% management.

% Thomas Deneux
% Copyright 2015-2017

error 'No MEX-file for fn_getPr was found for your system. Please compile fn_getPr.cpp'
