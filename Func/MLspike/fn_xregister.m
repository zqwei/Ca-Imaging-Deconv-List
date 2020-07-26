function d = fn_xregister(a,b,maxshift)
% function d = fn_xregister(a,b,maxshift)
%---
% register images a and b using cross-correlation
% based on the Matlab code for normxcorr2, and normalization is improved
% when a is not inside b
%
% Input:
% - a,b        images to register
% - maxshift   value between 0 and 1: maximal percentage of motion in x and
%              y direction
%              or maximal motions in number of pixels
%
% See also fn_register

% The MathWorks, Inc.
% Copyright 1993-2010 
% Thomas Deneux
% Copyright 2014-2017

if nargin==0, help fn_xregister, return, end
if nargin<3, maxshift = 0.2; end

[ni nj ncol] = size(a);
c = 0;
for i=1:ncol
    c = c + fastxcorr(a,b,maxshift)/ncol;
end

%figure(2), imagesc(c',[0 1])

[m imax] = max(abs(c(:))); %#ok<ASGLU>
[x y] = ind2sub(size(c),imax);
x = x-size(a,1); y = y-size(a,2);
d = [x y]; % how to translate a to match b
d = -d; % how much a is away from b

function c = fastxcorr(a,b,maxshift)
% comput correlation coefficitent
% c = sum((a-m(a)).*(b-m(b)) / sqrt(sum((a-m(a)).^2)sum((b-m(b)).^2))
%   = (sum(a.*b)-sum(a)sum(b)/n) / sqrt((sum(a.^2)-sum(a)^2/n)(sum(b.^2)-sum(b)^2/n))

a = rot90(a,2); % correlation rather than convolution

a = double(a);
b = double(b);
a = a-mean(a(:));
b = b-mean(b(:));

sa = size(a); sb = size(b); 

outsize = sa+sb-1;
maska = ones(sa);
maskb = ones(sb);

% Fourier domain
Fa = fft2(a,outsize(1),outsize(2));
Fb = fft2(b,outsize(1),outsize(2));
Fa2 = fft2(a.^2,outsize(1),outsize(2));
Fb2 = fft2(b.^2,outsize(1),outsize(2));
Fmaska = fft2(maska,outsize(1),outsize(2));
Fmaskb = fft2(maskb,outsize(1),outsize(2));

% Multiplication in Fourier domain <=> Convolution once back in time domain
n = real(ifft2(Fmaska .* Fmaskb));
suma = real(ifft2(Fa .* Fmaskb));
suma2 = real(ifft2(Fa2 .* Fmaskb));
sumb = real(ifft2(Fmaska .* Fb));
sumb2 = real(ifft2(Fmaska .* Fb2));
sumab = real(ifft2(Fa .* Fb));

% Final compute the correlation coefficients
vprod = (suma2-suma.^2./n).*(sumb2-sumb.^2./n);
% bad = (vprod<=0 | round(n)<minoverlap*min(numel(a),numel(b)));
% vprod(bad) = 0;
vprod(vprod<=0) = 0; % negative correlation becomes zero

% forbidden motion: not easy!
s = min(sa,sb);
if isscalar(maxshift)
    if maxshift<=1
        maxshift = floor(s*maxshift);
    else
        maxshift = maxshift([1 1]); 
    end
    % note that indices 1 and outsize correspond to (s-1) motion
    % therefore indices 1+(s-1)-maxshift and outsize-(s-1)+maxshift correspond to maxshift motion
    vprod([1:s(1)-1-maxshift(1) outsize(1)-s(1)+2+maxshift(1):outsize(1)],:) = 0;
    vprod(:,[1:s(2)-1-maxshift(2) outsize(2)-s(2)+2+maxshift(2):outsize(2)]) = 0;
end


c = (sumab-suma.*sumb./n) ./ sqrt(vprod);
c(vprod==0) = 0;
