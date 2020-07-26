function [a mincdist] = fn_getcolorindices(x,cm)
% function [a mincdist] = fn_getcolorindices(x,cm)
%---
% get indices in colormap for each pixel in image

% Thomas Deneux
% Copyright 2015-2017

[nx ny nc] = size(x);
if nc~=3, error 'first argument expected to be a color image', end
[ncol nc] = size(cm);
if nc~=3, error 'color map should have 3 columns', end

np = nx*ny;
x = reshape(double(x),[np 1 3]);
cm = reshape(cm,[1 ncol 3]);

cdist = sqrt(sum(fn_subtract(x,cm).^2,3)); % np x ncol
[m a] = min(cdist,[],2); % np x 1

a = reshape(a,[nx ny]);
mincdist = min(m);



