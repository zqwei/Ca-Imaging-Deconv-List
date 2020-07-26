function [y weight J dweight] = fn_translate(x,shift,varargin)
% function [y weight J dweight] = fn_translate(x,shift[,'full|valid'][,'linear|cubic'][,datatype])
%---
% Translate image (or movie) x by shift.
%
% Input:
% - x           2D or 3D array
% - shift       2, 3 or 4-element vector or 2/3/4-by-N array (N being the
%               number of frames) 
% - shapeflag   'full' [default] or 'valid', indicate whether to return y
%               the same size as x, or only the subpart where data is
%               defined
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
% See also fn_register

% Thomas Deneux
% Copyright 2009-2017

% Input
shapeflag = 'full'; method = 'cubic'; datatype = class(x);
for i=1:length(varargin)
    a = varargin{i};
    switch a
        case {'full' 'valid'}
            shapeflag = a;
        case {'linear' 'cubic'}
            method = a;
        case {'double' 'single' 'uint16' 'uint8' 'uint32'}
            datatype = a;
        otherwise
            error argument
    end
end

% movies
if size(x,3)>1
    [ni nj nt] = size(x);
    if ~isequal(size(shift),[2 nt]), error 'size mismatch for translation parameters', end
    y = zeros(ni,nj,nt,datatype);    
    for i=1:nt, y(:,:,i) = fn_translate(x(:,:,i),shift(:,i),'full',method,datatype); end
    if strcmp(shapeflag,'valid')
        if size(shift,1)>2
            error '''valid'' output shape can be achieved only for pure translation'
        end
        % which indices are ok: for security, do not try to guess 'to which
        % side integer numbers are rounded'
        switch method
            case 'linear'
                oki = ceil(max(shift(1,:))+1):floor(ni+min(shift(1,:))-1);
                okj = ceil(max(shift(2,:))+1):floor(nj+min(shift(2,:))-1);
            case 'cubic'
                oki = ceil(max(shift(1,:))+2):floor(ni+min(shift(1,:))-2);
                okj = ceil(max(shift(2,:))+2):floor(nj+min(shift(2,:))-2);
        end
        y = y(oki,okj,:);
    end
    return
end

% rotation and/or scaling?
if length(shift)>2
    if nargout>=2, error 'no weights available when performing rotation and/or scaling', end
    y = matrixInterpolation(x,shift);
    return
end

% Bi-cubic interpolation needs a grid of 4x4 points to define value in one
% point, i.e. 2 values in each left/right/up/down direcion.
% If we want to shift the image rightward, we need to look leftward when
% filling the new image 
dec = -double(shift);
% first attempt is deci = floor(dec), but for example if dec = 5, it is
% possible and preferrable to have deci = 4, because this will allows
% getting one more value defined on the right, hence the complicated
% formula below
deci = zeros(1,2);
for k=1:2
    if dec(k)>0, deci(k)=ceil(dec(k))-1; else deci(k)=floor(dec(k)); end
end
% coordinates inside the grid
u = dec(1)-deci(1);
v = dec(2)-deci(2);

% Parts of the input and output images to consider
[ni nj nt] = size(x);
switch method
    case 'linear'
        iin = max(1+(deci(1)),1):min(ni+(deci(1)+1),ni);
        jin = max(1+(deci(2)),1):min(nj+(deci(2)+1),nj);
        iout = max(1,1-(deci(1))):min(ni,ni-(deci(1)+1));
        jout = max(1,1-(deci(2))):min(nj,nj-(deci(2)+1));
    case 'cubic'
        iin = max(1+(deci(1)-1),1):min(ni+(deci(1)+2),ni);
        jin = max(1+(deci(2)-1),1):min(nj+(deci(2)+2),nj);
        iout = max(1,1-(deci(1)-1)):min(ni,ni-(deci(1)+2));
        jout = max(1,1-(deci(2)-1)):min(nj,nj-(deci(2)+2));
end

% corresponding weight
if nargout>=2
    if ~strcmp(method,'cubic'), error 'not implemented yet', end
    u2 = max(eps,min(1-eps,3*u^2-2*u.^3));
    v2 = max(eps,min(1-eps,3*v^2-2*v^3));
    weight = zeros(ni,nj);
    weight(iout,jout) = 1;
    dod = (nargout>=3);
    if dod, dweight = zeros(ni,nj,2); end
    if iout(1)  == 1-(deci(1)-1)
        if dod
            dweight(iout(1),:,1)   = weight(iout(1),:)*(-6*u*(1-u)); 
        end
        weight(iout(1),:)   = weight(iout(1),:)*u2; 
    end
    if iout(end)== ni-(deci(1)+2)
        if dod
            dweight(iout(end),:,1)  = weight(iout(end),:)*(+6*u*(1-u));
        end
        weight(iout(end),:) = weight(iout(end),:)*(1-u2);     
    end
    if jout(1)  == 1-(deci(2)-1)
        if dod
            dweight(:,jout(1),1)   = dweight(:,jout(1),1)*v2; 
            dweight(:,jout(1),2)   = weight(:,jout(1))*(-6*v*(1-v)); 
        end 
        weight(:,jout(1))   = weight(:,jout(1))*v2; 
    end
    if jout(end)== nj-(deci(2)+2)
        if dod
            dweight(:,jout(end),1) = dweight(:,jout(end),1)*(1-v2);
            dweight(:,jout(end),2) = weight(:,jout(end))*(+6*v*(1-v));
        end 
        weight(:,jout(end)) = weight(:,jout(end))*(1-v2); 
    end
    total  = sum(weight(:));
    if dod
        dtotal = sum(sum(dweight));
        dweight = dweight/total - cat(3,weight*dtotal(1),weight*dtotal(2))/total^2;
    end
    weight  = weight/total;
end
% take the needed part of x
y0 = x(iin,jin,:);
if strcmp(datatype,'double'), y0 = double(y0); else y0 = fn_float(y0); end

% Prepare for convolution
switch method
    case 'linear'
        filti = [1-u u];
        filtj = [1-v v];
    case 'cubic'
        % Spline Interpolation!
        % First the matrix from http://en.wikipedia.org/wiki/Bicubic_interpolation
        A = 1/2 * [0 2 0 0; -1 0 1 0; 2 -5 4 -1; -1 3 -3 1];
        filti = [1 u u^2 u^3]*A;
        filtj = [1 v v^2 v^3]*A;
end
filti = flipud(filti'); % using convolution instead of cross-correlation: must flip the filter
filtj = fliplr(filtj); 
% Convolution in the first dimension
u = dec(1)-deci(1);
y1 = convn(y0,filti,'valid');
% Convolution in the second dimension
v = dec(2)-deci(2);
y12 = convn(y1,filtj,'valid');

% Derivatives!
if nargout>=3
    if ~strcmp(method,'cubic'), error 'not implemented yet', end
    if nt>1, error('cannot compute derivative for a movie'), end
    dfiltidu = [0 1 2*u 3*u^2]*A;
    dfiltidu = flipud(dfiltidu');
    dfiltidv = [0 1 2*v 3*v^2]*A;
    dfiltidv = fliplr(dfiltidv);
    y2 = convn(y0,filtj,'valid');
    dy12du = convn(y2,dfiltidu,'valid');
    dy12dv = convn(y1,dfiltidv,'valid');
    dy12dshift = cat(3,-dy12du,-dy12dv);
end
    
% Fill-in the output
switch shapeflag
    case 'full'
        switch datatype
            case {'single' 'double'}
                y = nan(ni,nj,datatype);
            otherwise
                y = zeros(ni,nj,datatype);
        end
        y(iout,jout) = y12;
        if nargout>=3
            J = nan(ni,nj,2);
            J(iout,jout,:) = dy12dshift;
        end
    case 'valid'
        y = cast(y12,datatype);
        if nargout>=3, J = dy12dshift; end
    otherwise
        error('unknown shape flag ''%s''',shapeflag)
end

%---
function y = matrixInterpolation(x,shift)

[ni nj] = size(x);
center = [(1+ni)/2; (1+nj)/2];
theta = -shift(3);
if length(shift)>=4, scale = 2^shift(4); else scale = 1; end

M = scale*[cos(theta) -sin(theta); sin(theta) cos(theta)];
[ii jj] = ndgrid(1:ni,1:nj);
p = fn_add( ...
    M*[row(ii); row(jj)], ...   % inverse rotation with center (0,0)
    center-M*center ...         % translation to have a rotation with center the center of the image
    -column(shift(1:2)) ...         % inverse translation
    );

y = interpn(x,p(1,:),p(2,:),'spline',NaN);
y = reshape(y,ni,nj);


