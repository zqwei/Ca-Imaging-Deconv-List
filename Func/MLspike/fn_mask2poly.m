function poly = fn_mask2poly(mask)
% function poly = fn_mask2poly(mask)
%---
% Wraps Matlab Central mask2poly by Nikolay S. for easier manipulation.
% But uses opposite coordinates conventions! I.e. x = first coordinate, 
% y = second coordinate.
%
% See also fn_poly2mask

% Empty mask?
if ~any(mask)
    poly = zeros(0,2);
    return
end

% Cut the mask to reduce computation time
xproj = any(mask,2);
xfirst = find(xproj,1,'first');
xlast = find(xproj,1,'last');
yproj = any(mask,1);
yfirst = find(yproj,1,'first');
ylast = find(yproj,1,'last');
mask = mask(max(xfirst-1,1):min(xlast+1,end), max(yfirst-1,1):min(ylast+1,end));
xoffset = max(xfirst-1,1)-1;
yoffset = max(yfirst-1,1)-1;

% Apply mask2poly
poly = mask2poly(mask','Exact','CW');

% Put NaNs in the disconnections
sep = poly(:,1)<0; 
if sep(1) && ~any(sep(2:end))
    poly(sep,:) = [];
else
    poly(sep,:) = NaN;
end

% Add offset
poly = fn_add(poly,[xoffset yoffset]);



