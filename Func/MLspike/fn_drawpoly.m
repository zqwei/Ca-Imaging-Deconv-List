function hl = fn_drawpoly(poly,varargin)
% function hl = fn_drawpoly(poly[,'close'],line options...)
%---
% shortcut for line(poly(1,:),poly(2,:),varargin{:})
%
% See also fn_circle

% Thomas Deneux
% Copyright 2006-2017

if nargin==0, help fn_drawpoly, end

if size(poly,1)~=2
    if size(poly,2)==2
        poly = poly';
    else
        error('poly should have two rows')
    end
end
doclose = ~isempty(varargin) && strcmp(varargin{1},'close');
if doclose, varargin(1) = []; end
opt = fn_linespecs(varargin{:});
if doclose
    hl = line(poly(1,[1:end 1]),poly(2,[1:end 1]),opt{:});
else
    hl = line(poly(1,:),poly(2,:),opt{:});
end
if nargout==0, clear hl, end