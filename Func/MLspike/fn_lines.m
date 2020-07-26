function out = fn_lines(varargin)
% function hl = fn_lines([xcoordinates,ycoordinates[,zcoordinates]][,ha][,'close'][,'bottom'][,line options])
% function hl = fn_lines('x|y'[,xorycoordinates][,ha][,'close'][,'bottom'][,line options])
%---
% draw a series of vertical and/or horizontal lines

% Thomas Deneux
% Copyright 2004-2017

% Input
% (x or y only?)
[dox doy] = deal(true);
if nargin>=1 && ischar(varargin{1})
    switch varargin{1}
        case 'x'
            [dox doy] = deal(true,false);
            varargin(1)=[];
        case 'y'
            [dox doy] = deal(false,true);
            varargin(1)=[];
    end
end
% (auto coordinates?)
if ~isempty(varargin)
    a = varargin{1};
    carg = (isnumeric(a) && ~(isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')));
else
    carg = false;
end
% (coordinates)
[x y z] = deal([]);
if carg
    if dox, x = varargin{1}; varargin(1) = []; end
    if doy, y = varargin{1}; varargin(1) = []; end
    if ~isempty(varargin)
        a = varargin{1};
        doz = (isnumeric(a) && ~(isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')));
    else
        doz = false;
    end
    if doz, z = varargin{1}; varargin(1) = []; end
else
    doz = (length(axis)==6);
end
if doz && ~(dox && doy), error 'argument', end
x = fn_float(x); y = fn_float(y); z = fn_float(z);
% (other options)
ha = gca; doclose = false; dostackbottom = false; lineopt = {'color' 'k'};
for i=1:length(varargin)
    a = varargin{i};
    if isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')
        ha = a;
    elseif ischar(a)
        switch a
            case 'close'
                doclose = true;
            case 'bottom'
                dostackbottom = true;
            otherwise
                lineopt = [lineopt varargin(i:end)];
                break
        end
    end
end

% Auto-coordinates
if ~carg
    [x y z] = fn_get(ha,'xtick','ytick','ztick');
end

% Go
ax = axis(ha);
if ~doz
    % 2D
    if dox
        nx = length(x);
        hlx = zeros(1,nx);
        for k=1:nx
            hlx(k)=line([1 1]*x(k),ax([3 4]),lineopt{:},'parent',ha);
        end
    end
    if doy
        ny = length(y);
        hly = zeros(1,ny);
        for k=1:ny
            hly(k)=line(ax([1 2]),[1 1]*y(k),lineopt{:},'parent',ha);
        end
    end
else
    % 3D
    [nx ny nz] = deal(length(x),length(y),length(z));
    if doclose
        [xx yy zz] = deal(x([1 end]),y([1 end]),z([1 end]));
    else
        [xx yy zz] = deal(ax([1 2]),ax([3 4]),ax([5 6]));
    end
    hlxy = zeros(nx,ny);
    for i=1:nx
        for j=1:ny
            hlxy(i,j)=line([1 1]*x(i),[1 1]*y(j),zz,lineopt{:},'parent',ha);
        end
    end
    hlxz = zeros(nx,nz);
    for i=1:nx
        for k=1:nz
            hlxz(i,k)=line([1 1]*x(i),yy,[1 1]*z(k),lineopt{:},'parent',ha);
        end
    end
    hlyz = zeros(ny,nz);
    for j=1:ny
        for k=1:nz
            hlyz(j,k)=line(xx,[1 1]*y(j),[1 1]*z(k),lineopt{:},'parent',ha);
        end
    end
end

% output
if doz
    hl = {hlxy hlxz hlyz};
elseif dox && doy
    hl = {hlx hly};
elseif dox
    hl = hlx;
elseif doy
    hl = hly;
end
if nargout==1
    out = hl;
end
    
% stack to bottom
if dostackbottom
    if iscell(hl), hl = fn_map(hl,@row,'array'); end
    uistack(hl,'bottom')
end


