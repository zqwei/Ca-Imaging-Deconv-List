function hl = fn_arrow(xdata,ydata,varargin)
% function [hl =] fn_arrow(xdata,ydata[,tiplength[,tipangle[,thickness]]][,'simple|double'][,'line|patch'][,parname1,value1,...])
%---
% Draw an arrow
% 
% Input:
% - xdata,ydata     vectors of length 2 - coordinates of the main line of
%                   the arrow 
% - tiplength       scalar or 'x%' - tip length of the arrow expressed
%                   either as the length of its projection on the main
%                   line, or as a percentage of the main line [default:
%                   10%]
%                   can also be a cell array such as {'10%' .1}
% - tipangle        angle of the arrow tip [default 45°]
% - thickness       scalar between 0 and 1 - width of the line relative to
%                   the sides of the tip ('patch' mode only) [default:
%                   0.35]
% - 'simple' or 'double'    specify if one or two ends of the linehave an
%                   arrow [default: simple]
% - 'line' or 'patch'       arrow style [default: line]
% - parameter/value pairs   line or patch properties

% Thomas Deneux
% Copyright 2015-2017

% Input
if isscalar(xdata)
    xdata = xdata([1 1]);
elseif isscalar(ydata)
    ydata = ydata([1 1]);
end
if ~isvector(xdata) || length(xdata)~=2 || ~isvector(ydata) || length(ydata)~=2
    error 'xdata and ydata must be vectors of length 2'
end
tiplengthrel = [];
tipangle = [];
thickness = [];
ending = 'simple';
style = 'line';
opt = {};
for i=1:length(varargin)
    a = varargin{i};
    if isnumeric(a)
        if isempty(tiplengthrel)
            linelength = norm([diff(xdata) diff(ydata)]);
            tiplengthrel = a/linelength;
        elseif isempty(tipangle)
            tipangle = a;
        elseif isempty(thickness)
            thickness = a;
        else 
            error argument
        end
    elseif ischar(a)
        switch a
            case {'simple' 'double'}
                ending = a;
            case {'line' 'patch'}
                style = a;
            otherwise
                tokens = regexp(a,'^([\d]*(\.\d+){0,1})%$','tokens');
                if ~isempty(tokens)
                    tiplengthrel = str2double(tokens{1}{1})/100;
                else
                    opt = varargin(i:end);
                    break
                end
        end
    elseif iscell(a) && isempty(tiplengthrel)
        tokens = regexp(a{1},'^([\d]*(\.\d+){0,1})%$','tokens');
        linelength = norm([diff(xdata) diff(ydata)]);
        tiplengthrel = str2double(tokens{1}{1})/100 + a{2}/linelength;        
    else
        error argument
    end
end
if isempty(tiplengthrel), tiplengthrel = 0.1; end
if isempty(tipangle), tipangle = 45; end
if isempty(thickness), thickness = 0.35; end

% axes handle
kparent = find(strcmpi(opt(1:2:end),'parent'));
if isempty(kparent)
    ha = gca;
else
    ha = opt{2*kparent};
end
% convert line to pixel coordinates
lineax = [xdata(:)'; ydata(:)'];
linepx = fn_coordinates(ha,'a2b',lineax,'position');
% create the arrow
a = linepx(:,1);
b = linepx(:,2);
u = tiplengthrel*(b-a);
v = [u(2); -u(1)] * tand(tipangle);
N = [NaN; NaN];
switch [style ending]
    case 'linesimple'
        arrowpx = [a b N b b-u+v N b b-u-v];
    case 'linedouble'
        arrowpx = [a b N a a+u+v N a a+u-v N b b-u+v N b b-u-v];
    case 'patchsimple'
        arrowpx = [a+v*thickness b-u+v*thickness b-u+v b b-u-v b-u-v*thickness a-v*thickness];
    case 'patchdouble'
        arrowpx = [a a+u+v a+u+v*thickness b-u+v*thickness b-u+v b b-u-v b-u-v*thickness a+u-v*thickness a+u-v];
end
% convert arrow to axes coordinates
arrowax = fn_coordinates(ha,'b2a',arrowpx,'position');

% draw it
switch style
    case 'line'
        hl = line(arrowax(1,:),arrowax(2,:),'parent',ha);
    case 'patch'
        hl = patch('xdata',arrowax(1,:),'ydata',arrowax(2,:),'parent',ha,'edgecolor','none');
end

% additional options
kcolor = find(strcmpi(opt(1:2:end),'color'));
if ~isempty(kcolor) && strcmp(style,'patch')
    opt{kcolor} = 'facecolor';
end
if ~isempty(opt), fn_set(hl,opt{:}), end

% output?
if nargout==0, clear hl, end


