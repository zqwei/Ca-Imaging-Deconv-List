function fn_displayarrows(varargin)
% function fn_displayarrows([[x,y,]img,]arrows,sub,flag)
%---
% Input
% - x,y         vectors
% - img         array
% - arrows      array (...) or 2-element cell array
% - sub         scalar or 2-element vector
% - flag        ''
%
% USES MATLAB CONVENTIONS FOR IMAGES (i.e. rows <-> y, columns <-> x)

% Thomas Deneux
% Copyright 2005-2017

% Input
x = []; y = []; img = []; arrows = []; sub = 1; flag = 'fit';
for i=1:nargin
    a = varargin{i};
    if ischar(a)
        flag = a;
    elseif iscell(a)
        if ~isempty(arrows)
            if ~isempty(img)
                error argument
            end
            img = arrows;
        end
        arrows = a;
    elseif length(a)<=2
        sub = a;
    elseif isvector(a)
        if isempty(x)
            x = a;
        elseif isempty(y)
            y = a;
        else
            error argument
        end
    elseif isempty(arrows)
        arrows = a;
    elseif isempty(img)
        img = arrows;
        arrows = a;
    elseif isempty(x)
        error argument
    end
end
if ~iscell(arrows)
    error('not implemented yet')
end
ux = arrows{1};
uy = arrows{2};
[ny nx] = size(arrows{1});
if isempty(x)
    x = 1:nx;
    y = 1:ny;
end

% Display image
if ~isempty(img)
    imagesc(x,y,img)
end

% Sub
if isscalar(sub)
    sub = [sub sub];
end

ix = 1:sub(1):nx;
iy = 1:sub(2):ny;

x = x(ix);
y = y(iy);

% Scale arrows
switch flag
    case 'fit'
        v = ux.^2 + uy.^2;
        fact = .5 / max(v(:));
    otherwise
        error('unknown flag ''%s''',flag)
end
ux = ux(iy,ix)*fact;
uy = uy(iy,ix)*fact;

% Display arrows
hold on
quiver(x,y,ux,uy,'hittest','off')
hold off





