function x = fn_detrend(x,frames,varargin)
% function y = fn_detrend(x,frames[,dim][,'subtract|normalize|keepmean'])
%---
% Correct signals for a trend that is estimated only from the specified
% frames.
%
% Input:
% - x       array - data
% - frames  vector of indices or logicals - reference frames to use for
%           detrending 
% - flag    'subtract' subtracts the estimated trend (constand and linear
%           parts) [default]
%           'normalize' divides by the linear part (i.e. mean over the
%           reference frames becomes 1)
%           'keepmean' subtracts the linear part (i.e. the mean over the
%           reference frames remains the same)

% Thomas Deneux
% Copyright 2015-2017

% Input
if islogical(frames)
    nframes = sum(frames);
else
    nframes = length(frames);
end
dim = 1; flag = 'subtract';
for k=1:length(varargin)
    a = varargin{k};
    if ischar(a)
        flag = a;
        if ~fn_ismemberstr(flag,{'subtract' 'normalize' 'keepmean'})
            error('unknown flag ''%s''',flag)
        end
    else
        dim = a;
    end
end

% sizes
s = size(x);
ndim = ndims(x);
nfr = s(dim);

% buil regressor(s)
constant = ones(1,nfr) / sqrt(nframes);          % constant(frames) is a normal vector
linear = 1:nfr;
linear = linear - (linear(frames)*constant(frames)')*constant;  % now constant(frames) and linear(frames) are orthogonal
linear = linear / norm(linear(frames));                      % now constant(frames) and linear(frames) are orthonormal
A = [constant; linear];

% perform detrending
x = fn_reshapepermute(x,{1:dim-1 dim dim+1:ndim});
nc = size(x,3);
for k=1:nc
    xk = x(:,:,k);
    xkframes = xk(:,frames);
    switch flag
        case 'subtract'
            xk = xk - (xkframes*A(:,frames)')*A;  % operation on columns
        case 'normalize'
            beta = xkframes*A(:,frames)';
            xk = (xk - beta(2)*linear) ./ (beta(1)*constant);
        case 'keepmean'
            xk = xk - (xkframes*linear(frames)')*linear;
    end
    x(:,:,k) = xk;
end
x = reshape(x,s);
