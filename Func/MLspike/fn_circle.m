function hl = fn_circle(x,y,r,varargin)
% function hl = fn_circle(x,y,r[,'yadjust'][,patch options])
%---
% display circle(s) as patch objects
%
% if 'yadjust' flag is used, it is in fact an ellipse that will be defined
% in x-y coordinates, to counteract specific data aspect ratio in the
% figure and therefore ensure that the final aspect of these ellipses will
% actually be circles (in this case, rx specifies the radius in
% x-coordinates, while the radius in y-coordinates will be adjusted)
% 
% See also fn_drawpoly

% Thomas Deneux
% Copyright 2015-2017

% Input
n = unique([numel(x),numel(y),numel(r)]);
if ~isscalar(n)
    n = setdiff(n,1);
    if ~isscalar(n), error 'size mismatch', end
    if isscalar(x), x = repmat(x,1,n); end
    if isscalar(y), y = repmat(y,1,n); end
    if isscalar(r), r = repmat(r,1,n); end
end
doyadjust = ~isempty(varargin) && strcmp(varargin{1},'yadjust');
if doyadjust, varargin(1) = []; end

% Adjust y-radius
kparent = find(strcmpi(varargin(1:2:end),'parent'));
if isempty(kparent), ha = gca; else ha = varargin(2*kparent); end
if doyadjust
    dar = get(ha,'DataAspectRatio');
    yadjust = dar(2)/dar(1);
else
    yadjust = 1;
end

% Standard circle coordinates
nsub = 20;
theta = (0:nsub-1)/nsub*(2*pi);
x0 = cos(theta); y0 = yadjust*sin(theta);

% Display
hl = gobjects(size(x));
for i=1:n
    hl(i) = patch(x(i)+r(i)*x0,y(i)+r(i)*y0,0,varargin{:});
end

% Output?
if nargout==0, clear hl, end
