function [y weight] = fn_affinity(x,M,varargin)
% function [y weight] = fn_affinity(x,M[,'linear|cubic'][,datatype])
%---
% Perform affine transformation on an image.
%
% Input:
% - x           2D or 3D array
% - shift       2-element vector or 2-by-N array (N being the number of
%               frames) 
% - method      'linear' or 'cubic' [default]
% - datatype    data type to save output, typically 'double' or 'single',
%               default is same as data
%
% Output:
% - y       the translated image or movie (points where data is not defined
%           have a NaN value)
% - weight  image the same size of x with values btw 0 and 1: weighting
%           system for getting values of y as a continuous-derivative
%           function of shift, even at integer values of shift
%           use also logical(weight) to get the pixels whose values are
%           defined in y
% - J       derivative of y with respect to shift (points where it is not
%           defined also have a NaN value)
% - dweight derivative of weight with respect to shift
%
% See also fn_register, fn_translate

% Thomas Deneux
% Copyright 2014-2017

% Input
shapeflag = 'full'; method = 'cubic'; datatype = class(x);
for i=1:length(varargin)
    a = varargin{i};
    switch a
        case {'double' 'single' 'uint16' 'uint8'}
            datatype = a;
        case {'linear' 'cubic'}
            method = a;
        otherwise
            error argument
    end
end

% movies
if size(x,3)>1
    [ni nj nt] = size(x);
    if ~isequal(size(M),[3 3 nt]), error 'size mismatch for translation parameters', end
    y = zeros(ni,nj,nt,datatype);
    for i=1:nt, y(:,:,i) = fn_translate(x(:,:,i),M(:,:,i),'full',method,datatype); end
    if strcmp(shapeflag,'valid')
        error 'not implemented yet'
    end
    return
end
    

% Bi-cubic interpolation needs a grid of 4x4 points to define value in one
% point, i.e. 2 values in each left/right/up/down direcion.
% We want to transorm image x by transformation M, so for each pixel p of
% the result image y we need to interpolate the value at pixel M^-1(p) in x
M1 = M^-1;
M1 = M1(2:3,:);
[ni nj] = size(x);
[ii jj] = ndgrid(1:ni,1:nj);
q = M1 * [ones(1,ni*nj); row(ii); row(jj)];
qi = floor(q);
idx = (q(1,:)==ni); qi(1,idx) = qi(1,idx)-1; % do this so that interpolation will not fail at pixel position with i=ni or j=nj
idx = (q(2,:)==nj); qi(2,idx) = qi(2,idx)-1;

% Mask
mask = (all(qi>=1) & qi(1,:)<ni & qi(2,:)<nj);
mask = reshape(mask,[ni nj]);

% Interpolation
qm = q-qi;
u = qm(1,mask);
v = qm(2,mask);
qidx = qi(1,mask) + ni*(qi(2,mask)-1);
y = zeros(ni,nj,datatype);
switch method
    case 'linear'
        y(mask) = (1-u).*(1-v).*x(qidx) ...
            +     (1-u).*   v .*x(qidx+ni) ...
            +        u .*(1-v).*x(qidx+1) ...
            +        u .*   v .*x(qidx+ni+1);
    case 'cubic'
        error 'not implemented yet'
end

% Weight
weight = mask;



