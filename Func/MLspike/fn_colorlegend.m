function hleg = fn_colorlegend(varargin)
% function [hleg =] fn_colorlegend([handles,]names[,'NorthWest|...'][,'frame'][,text options...])
%---
% Display discreet color legend for set of lines

% Input
if nargin==0
    figure(1), clf
    hl = plot(rand(100,5));
    names = {'a first line' 'a second one' 'number 3' '4' 'and five'};
else
    i=0;
    textopt = {}; hl = []; location = 'NorthWest'; doframe = false;
    while i<nargin
        i = i+1;
        a = varargin{i};
        if iscell(a)
            names = a;
        elseif ischar(a)
            switch lower(a)
                case {'northwest' 'northeast' 'southwest' 'southeast'}
                    location = a;
                case 'frame'
                    doframe = true;
                otherwise
                    textopt = varargin(i:end);
                    break
            end
        elseif all(ishandle(a))
            hl = a;
        else
            error argument
        end
    end
    if isempty(hl)
        hl = flipud(findobj(gca,'type','line'));
    end
end

% Parent axes
n = numel(hl);
ha = fn_parentaxes(hl(1));
for i=2:n
    if ~isequal(fn_parentaxes(hl(i)),ha)
        error 'all objects must be in the same parent axes'
    end
end
hp = get(ha,'parent');
hf = fn_parentfigure(ha);

% Legend axes
hleg = axes('parent',hp,'pos',[.4 .4 .2 .2],'units','pixel','handlevisibility','off');
set(hleg,'visible',fn_switch(doframe))
[w h] = fn_pixelsize(hleg);
set(hleg,'xlim',[0 w],'ylim',[-h 0]) % use pixel coordinate systems to ease everything
set(hleg,'xtick',[],'ytick',[],'box','on') % some esthetics

% Display names
ht = zeros(1,n); extents = zeros(n,4);
for i=1:n
    ht(i) = text(0,0,names{i},'parent',hleg, ...
        'color',get(hl(i),'color'),textopt{:});
    extents(i,:) = get(ht(i),'Extent');
end

% Dispatch them vertically and make the legend axes the appropriate size
ystep = max(extents(:,4))*.9;
for i=1:n
    set(ht(i),'pos',[0 -i*ystep])
    extents(i,:) = get(ht(i),'Extent');
end
[xmargin ymargin] = deal(5,0);
W = max(extents(:,3)) + 2*xmargin;
top = max(extents(:,2)+extents(:,4));
bottom = min(extents(:,2));
H = top - bottom + 2*ymargin;
set(hleg,'pos',[100 100 W H], ...
    'xlim',[-xmargin -xmargin+W],'ylim',[bottom-ymargin top+ymargin])

% Position according to location flag
margin = 5;
switch lower(location)
    case 'northwest'
        posrel = [0 1];
        pospix = [margin 1-H-margin W H];
    case 'northeast'
        posrel = [1 1];
        pospix = [1-W-margin 1-H-margin W H];
    case 'southwest'
        posrel = [0 0];
        pospix = [margin margin W H];
    case 'southeast'
        posrel = [1 0];
        pospix = [1-W-margin margin W H];
end
fn_controlpositions(hleg,ha,posrel,pospix)

% Moving the legend
set([hleg ht],'buttondownFcn',@(u,e)moveLegend(hleg,ha,W,H))

% Menu for deleting and hiding/showing frame
m = uicontextmenu('parent',hf);
fn_propcontrol(hleg,'Visible','menu',{m,'label','Show legend''s frame'});
uimenu(m,'label','Delete legend','callback',@(u,e)delete(hleg))
set([hleg ht],'UIContextMenu',m)

% Delete legend upon deletion of the lines
fn_deletefcn(ht,@(u,e)deleteValid(hleg))

% Output
if nargout==0, clear hleg, end

%---
function moveLegend(hleg,ha,W,H)


fn_moveobject(hleg,'pointer','fleur');

pos = fn_pixelpos(hleg);
center = [pos(1)+pos(3)/2 pos(2)+pos(4)/2];  
posa = fn_pixelpos(ha);
posrel = [(center(1)-posa(1))/posa(3) (center(2)-posa(2))/posa(4)];
pospix = [-W/2 -H/2 W H];

fn_controlpositions(hleg,ha,posrel,pospix)


