function I = fn_smooth3(I,sigma)
% function I = fn_smooth3(I,sigma)
%---
% 3D smoothing with gaussian kernel convolution
% filter half-width is sigma
% window length is 2*ceil(sigma)+1

% Thomas Deneux
% Copyright 2005-2017

n = 2*ceil(sigma)+1;
filt = fspecial('gaussian',[n 1],sigma);
filt3 = repmat(filt*filt',[1 1 n]).*repmat(shiftdim(filt,-2),[n n 1]);
I = convn(I,filt3,'same');

