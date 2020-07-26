function varargout = fn_menu(varargin)
% function m = fn_menu([fig,]'h'|'v',title,width,height,'FramePropertyName',FramePropertyValue,...)
% function u = fn_menu(m,'UIControlPropertyName',UIControlPropertyValue,...)
% function [m u] = fn_menu([menu options],'add',[first control options],'add',[second control options],...)
%---
% creates a frame uicontrol and provides facilities to put new uicontrols
% inside

% Thomas Deneux
% Copyright 2006-2017

% Create figure?
if nargin==0 || ischar(varargin{1})
    h = createfigure;
    doresizefig = true;
else
    h = varargin{1};
    varargin(1) = [];
    doresizefig = false;
end
docreate = fn_ismemberstr(get(h,'type'),{'figure' 'uipanel'});
if docreate
    hf = h;
else
    m = h;
    hf = get(m,'parent');
end

% Scan input and separate along 'add' keywords
u = [];
nitem = 0;
istart = 1;
icur = 0;
while icur <= length(varargin)
    if icur==length(varargin) || (ischar(varargin{icur+1}) && strcmp(varargin{icur+1},'add'))
        if docreate
            m = createmenu(hf,doresizefig,varargin{istart:icur});
            docreate = false;
        else
            u(end+1) = addcontrol(m,varargin{istart:icur}); %#ok<AGROW>
        end
        istart = icur+2;
        icur = icur+1;
        nitem = nitem+1;
    end
    icur = icur+1;
end
   
% Output
if nargout>0
    if isempty(u)
        varargout = {m};
    elseif nitem==1
        varargout = {u};
    elseif nargout==1;
        varargout = {m};
    elseif nargout==2
        varargout = {m u};
    end
end

function hf = createfigure

hf = figure;
clf reset
set(hf,'menubar','none')

function m = createmenu(hf,doresizefig,varargin)

if nargin<3, align='v'; else align=varargin{1}; end
if nargin<4, title=''; else title=varargin{2}; end
if nargin<5, width=30; else width=varargin{3}; end
if doresizefig
    % on windows at least, figure cannot have a width below 116
    % pixels
    width = max(width,96);
end
if nargin<6, height=20; else height=varargin{4}; end
switch align
    case {'v','h'}
        position = [5 5 width+10 height+10];
    otherwise
        error('unknown align flag ''%s''',align)
end
m = uicontrol('parent',hf,'style','frame','position',position,varargin{5:end},...
    'deletefcn',{@kill});
if doresizefig, fn_setfigsize(hf,position(3:4)+10), end
info = struct('align',align,'width',width,'height',height,...
    'title',title,'doresizefig',doresizefig,'children',[]);
setappdata(m,'fn_menu',info);


function u = addcontrol(m,varargin)

hf = get(m,'parent'); % parent figure
info = getappdata(m,'fn_menu');

% add control
u = uicontrol('parent',hf,varargin{:});
info.children(end+1) = u;
setappdata(m,'fn_menu',info)

% update positions
position = controlposition(0,info);
set(m,'Position',position)
if info.doresizefig, fn_setfigsize(hf,position(3:4)+10), end
for i = 1:length(info.children)
    set(info.children(i),'Position',controlposition(i,info))
end



function position = controlposition(i,info)

n = length(info.children);
switch info.align
    case 'v'    % vertical alignment
        if i==0     % frame
            position = [5 5 (info.width+10) (n*info.height+max(0,n-1)*2+10)];
        else        % child uicontrol
            position = [10 (10+(n-i)*(info.height+2)) info.width info.height];
        end
     case 'h'    % horizontal alignment
        if i==0     % frame
            position = [5 5 (n*info.width+max(0,n-1)*2+10) (info.height+10)];
        else        % child uicontrol
            position = [(10+(i-1)*(info.width+2)) 10 info.width info.height];
        end
end
       


%---
function kill(m,dum) %#ok<INUSD>

info = getappdata(m,'fn_menu');
delete(info.children(ishandle(info.children)))




