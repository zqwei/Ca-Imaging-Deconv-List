function mask = fn_poly2mask(xpoly,ypoly,m,n)
% function mask = fn_poly2mask(xpoly,ypoly,m,n)
% function mask = fn_poly2mask(poly,sizes)
%---
% Do the same as Matlab poly2mask without needing the Image Toolbox
% Except use different convention!! I.e. x = first coordinate, y = second
% coordinate.
%
% See also fn_mask2poly

% Thomas Deneux
% Copyright 2015-2017

% input
switch nargin
    case 0
        help fn_poly2mask
    case 4
        % the default input formatting, nothing to do
    case 2
        [poly sizes] = deal(xpoly,ypoly);
        xpoly = poly(1,:); ypoly = poly(2,:);
        m = sizes(1); n = sizes(2);
    case 3
        if isscalar(xpoly)
            error 'input is ambiguous'
        elseif isscalar(ypoly)
            [poly m n] = deal(xpoly,ypoly,m);
            xpoly = poly(1,:); ypoly = poly(2,:);
        else
            [xpoly ypoly sizes] = deal(xpoly,ypoly,m);
            m = sizes(1); n = sizes(2);
        end
    otherwise
        error 'wrong number of inputs'
end

% need to test only a sub-rectangle
imin = max(1,round(min(xpoly)));
imax = min(m,round(max(xpoly)));
jmin = max(1,round(min(ypoly)));
jmax = min(n,round(max(ypoly)));

% apply function taken from Matplotlib
try
    submask = point_in_path_impl(xpoly-(imin-1),ypoly-(jmin-1),imax-imin+1,jmax-jmin+1);
catch
    if fn_dodebug
        disp 'please check what happened here!'
        keyboard
    end
end
mask = false(m,n);
mask(imin:imax,jmin:jmax) = submask;

% % show it
% figure(fn_figure('test'))
% imagesc(mask'), axis image
% patch(xpoly,ypoly,'k','facecolor','none','edgecolor','k')

% no output?
if nargout==0, clear mask, end

% function from Matplotlib (https://github.com/matplotlib/matplotlib/blob/196f3446a3d5178c58144cee796fa8e8aa8d2917/src/_path.h, line 77+)
function mask = point_in_path_impl(xpoly,ypoly,ni,nj)

% pixel coordinates
ii = (1:ni)';
jj = 1:nj;
[iii jjj] = ndgrid(ii,jj);

% poly
nsegment = length(xpoly);

% output
mask = false(ni,nj);

% first vertex
[sx sy] = deal(xpoly(1),ypoly(1));

% loop on path segments
for isegment = 1:nsegment
    % 2 points of the segment
    ipt0 = isegment; ipt1 = 1+mod(isegment,nsegment);
    [x0 x1 y0 y1] = deal(xpoly(ipt0),xpoly(ipt1),ypoly(ipt0),ypoly(ipt1));
        
    % invert values of points below the segment
    icheck = xor(ii<=x0,ii<=x1); % points in grid with abscissae inside the x-span of the segment
    if ~any(icheck), continue, end
    maskcheck = mask(icheck,:);
    rightpath = bsxfun(@ge,(y1-jj)*(x0-x1),(x1-ii(icheck))*(y0-y1)); % points in grid on the right of path when going from point 0 to point 1
    if x0<x1, doinvert = rightpath; else doinvert = ~rightpath; end
    maskcheck(doinvert) = ~maskcheck(doinvert);
    mask(icheck,:) = maskcheck;
    
    %     % display
    %     figure(1), imagesc(mask'), axis image, pause
end

