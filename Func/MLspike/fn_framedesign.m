function [pos cmd] = fn_framedesign(grob,pos,resetflag)
% function [pos cmd] = fn_framedesign([grob[,pos|cmd[,resetflag]]])
%---
% utility for positioning frames in a figure
%
% Input:
% - grob        structure with fields the names of graphic objects
%               considered and values their handles; their must be one
%               field 'hf' for the main figure
% - pos         structure with fields the names of graphic objects and
%               values their positions; fields are allowed to differ from
%               those of 'grob'
%               pos can also be the name of a mat file where the position
%               parameters are saved
% - cmd         string defining pos (should be something like
%               'pos.hf=[..]; ...')
% - resetflag   true [default] or false - user resize?
%
% Output:
% - pos         as above
% - cmd         as above

% Thomas Deneux
% Copyright 2007-2017

% Input
% (make grob a structure with a 'hf' field)
if nargin<1, grob = gcf; end
if isscalar(grob) && ishandle(grob) && strcmp(get(grob,'type'),'figure')
    hf = grob;
    obj = get(hf,'children')';
    obj = fliplr(obj);
    objtype = get(obj,'type');
    grob = struct( ...
        'hf',       hf, ...
        'panels',   obj(strcmp(objtype,'uipanel')), ...
        'axes',     obj(strcmp(objtype,'axes')), ...
        'controls', obj(strcmp(objtype,'uicontrol')), ...
        'tables',   obj(strcmp(objtype,'uitable')));
elseif all(ishandle(grob))
    obj = grob;
    i = find(strcmp(get(obj,'type'),'figure'),1,'first');
    if isempty(i), obj(end+1)=get(obj(1),'parent'); i=length(obj); end
    hf = obj(i); obj = obj(setdiff(1:length(obj),i));
    grob = struct('hf',hf,'obj',obj); 
elseif ~isfield(grob,'hf')
    F=fieldnames(grob); grob.hf = get(grob.(F{1})(1),'parent'); 
end
% (handle sub-structures)
grob = flattenstruct(grob);
% (positions given as an argument, or a file, or a file linked to an .m
% file)
dosavefile = false;
if nargin<2
    if isappdata(hf,'fn_framedesign')
        info = getappdata(hf,'fn_framedesign');
        grob = info.grob;
        fname = info.fname;
        dosavefile = true;
        pos = fn_loadvar(fname);
    else
        pos = [];
    end
elseif ischar(pos)
    fm = which(pos);
    if strfind(fm,'is a built-in method'), fm=''; end
    if ~isempty(fm)
        fname = [fn_fileparts(fm,'noext') '.mat'];
    else
        ext = fn_fileparts(pos,'ext');
        if ~isempty(ext) && ~strcmp(ext,'.mat'), error 'file must have a .mat extension', end
        fname = [fn_fileparts(pos,'noext') '.mat'];
    end
    dosavefile = true;
    if exist(fname,'file')
        pos = fn_loadvar(fname);
    else
        pos = [];
    end
end
% (reset flag)
if nargin<3, resetflag = []; end

% Make a vector of all objects - remember names and numbers
F = fieldnames(grob);
obj = [];
field = {};
num = [];
for k=1:length(F)
    f = F{k};
    nk = length(grob.(f));
    obj = [obj grob.(f)(:)'];
    field = [field repmat({f},1,nk)];
    num = [num 1:nk];
end

% Set positions according to 'pos'
state.units = fn_get(obj,'units');
newgrob = true;
if nargin>1
    if ischar(pos), eval(pos), end
    newgrob = false;
    F = fieldnames(grob);
    for k=1:length(F)
        f = F{k};
        if ~isfield(pos,f) || size(pos.(f),1)~=numel(grob.(f))
            newgrob = true;
        end
        if isfield(pos,f)
            %             if strcmp(f,'hf')
            %                 % do not move the figure, only resize it
            %                 fn_setfigsize(grob.hf,pos.hf(3:4))
            %                 continue
            %             end
            for i=1:min(size(pos.(f),1),numel(grob.(f)))
                obji = grob.(f)(i);
                posi = pos.(f)(i,:);
                if posi(3)<1
                    set(obji,'units','normalized')
                else
                    set(obji,'units','pixel')
                end
                set(obji,'position',posi)
            end
        end
    end
end

% % Correct figure position however to make it visible if necessary
% screensize = get(0,'screenSize');
% if ~isempty(pos) && isfield(pos,'hf') && ...
%         (pos.hf(1)+pos.hf(3)>screensize(3) || pos.hf(2)+pos.hf(4)>screensize(4))
%     set(grob.hf,'position',[4 screensize(4)-pos.hf(4)-52 pos.hf(3:4)])
% end

% Finish if we don't want to (re)define the positions
if isempty(resetflag), resetflag = newgrob; end
if ~resetflag
    fn_set(obj,'units',state.units) % restore 'units' properties in case they have been modified
    if dosavefile 
        if ~exist(fname,'file') 
            if fn_dodebug, disp 'i don''t understand when this can happen (i.e. resetflag=false but file not existing)', keyboard, end %#ok<DUALC>
            fn_savevar(fname,pos)
        end
        attachdata(grob.hf,grob,fname)
    end
    if nargout==0, clear pos, end
    return
end

%---
% Here we enter user editing
%---

figure(grob.hf)

% Store properties which will be changed
%hc=cell2mat(fn_get(obj,'children')); hc = hc(:)';
hc=findall(obj); hc = hc(:)';
hctype = fn_get(hc,'type');
hc(fn_ismemberstr(hctype,{'uimenu','uicontextmenu'})) = [];
state.children = setdiff(hc,obj);
state.allobj = [obj state.children];
state.objprop = fn_get(obj,{'buttondownfcn' 'visible' 'units'},'struct');
state.childprop = fn_get(state.children,'hittest','struct');
type = fn_get(obj,'type');
state.figures = obj(fn_ismemberstr(type,'figure'));
state.figprop = fn_get(state.figures,{'resize' 'resizefcn' 'windowbuttondownfcn'},'struct');
state.axes = obj(fn_ismemberstr(type,'axes'));
state.axesprop = fn_get(state.axes,{'DataAspectRatio' 'DataAspectRatioMode' 'Box'},'struct');
state.uicontrols = state.allobj(ismember(get(state.allobj,'type'),{'uicontrol' 'uitable'}));
state.uicontrolprop = fn_get(state.uicontrols,{'enable','buttondownfcn'},'struct');
state.panels = state.allobj(strcmp(get(state.allobj,'type'),'uipanel'));
state.panelprop = fn_get(state.panels,{'bordertype' 'borderwidth'},'struct');

% Scales
info.hf = grob.hf;
info.scales = [1 2 4 8 16 32 64 128 256];
scalek = 4; nscales = length(info.scales);

% Special buttons
pospanel = [2 102 96 24];
panel = uipanel('parent',info.hf,'units','pixels','position',pospanel, ...
    'buttondownfcn',@(hp,evnt)movepanel(hp,pospanel));
info.scale = pointer(info.scales(scalek));
info.scaleht = uicontrol('parent',panel,'style','text', ...
    'units','pixels','position',[21 1 30 16], ...
    'string',num2str(getvalue(info.scale)), ...
    'buttondownfcn',@(hu,evnt)movepanel(panel,pospanel),'enable','inactive');
uicontrol('parent',panel,'style','slider', ...
    'units','pixels','position',[1 1 20 20], ...
    'value',scalek,'sliderstep',[1 1]/(nscales-1),'min',1,'max',length(info.scales), ...
    'callback',@(hu,evnt)scaleupdate(info,hu)); % update value control
donehu = uicontrol('parent',panel,'style','pushbutton', ...
    'units','pixels','position',[53 1 40 20], ...
    'string','done','callback','delete(gcbo)');

% Change some properties
set(obj,'units','pixels','visible','on', ...
    'buttondownfcn',@(hobj,evnt)frameresize(info,hobj))
set(state.children,'hittest','off')
set(state.figures,'buttondownfcn','','windowbuttondownfcn','', ...
    'resize','on','resizefcn',@(hf,evnt)figureresize(info,hf))
% set(state.axes,'dataaspectratiomode','auto')
for ha=state.axes, axis(ha,'normal'), end % strange that line above is not enough...
set(state.axes,'box','on')
set(state.uicontrols,'enable','inactive')
for k=find(strcmp(get(obj,'type')','uipanel'))
    controlsk = findall(obj(k),'type','uicontrol');
    set(controlsk,'buttondownfcn',@(u,evnt)frameresize(info,obj(k)))
end
set(state.panels,'bordertype','line','borderwidth',1)

% Wait
waitfor(donehu)

% Remove special buttons
delete(panel)

% Get position information (in 'pixel' units!)
iobj = 0;
for k=1:length(F)
    f = F{k};
    nk = numel(grob.(f));
    positions = get(obj(iobj+(1:nk)),'position');
    if ~iscell(positions), positions = {positions}; end
    pos.(f) = cat(1,positions{:});
    iobj = iobj+nk;
end

% Restore old property values
fn_set(obj,state.objprop)
fn_set(obj,'units',state.units) % restore 'units' properties in case they have been modified
fn_set(state.children,state.childprop)
fn_set(state.figures,state.figprop)
% for k=1:length(state.figures)
%     posk = get(state.figures(k),'pos'); % bug! changing 'resize' property changes the size!
%     set(state.figures(k),'resize',state.figureresize{k}), drawnow
%     set(state.figures(k),'pos',posk); 
% end
fn_set(state.axes,state.axesprop)
fn_set(state.uicontrols,state.uicontrolprop)
fn_set(state.panels,state.panelprop)

% Save the new pos
if dosavefile
    fn_savevar(fname,pos)
    attachdata(grob.hf,grob,fname)
end
if (nargout==0 && ~dosavefile) || nargout==2
    cmd = [];
    for k=1:length(F)
        f = F{k};
        nk = numel(grob.(f));
        cmdk = ['pos.' f ' = ['];
        for i=1:nk
            cmdk = [cmdk fn_strcat(round(pos.(f)(i,:)),' ')]; %#ok<*AGROW>
            if i<nk, cmdk = [cmdk '; ']; end %#ok<*AGROW>
        end
        cmdk = [cmdk '];'];
        cmd = char(cmd,cmdk); 
    end
    if nargout==0
        disp(cmd)
        clear pos
    end
end


%-----------%
% CALLBACKS %
%-----------%

function scaleupdate(info,hu)

setvalue(info.scale,info.scales(get(hu,'value')));
set(info.scaleht,'string',num2str(getvalue(info.scale)))

%---
function figureresize(info,hf)

pos = get(hf,'position');
pos(3:4) = getvalue(info.scale)*(round(pos(3:4)/getvalue(info.scale)))
set(hf,'position',pos)

%---
function frameresize(info,hobj)

pos = get(hobj,'position');
hf = get(hobj,'parent');
posf = get(hf,'position');
p = get(0,'pointerlocation')-posf(1:2);
TOL = 3;
disp(get(hf,'SelectionType'))
switch get(hf,'SelectionType')
    case 'normal'
        p = p-pos(1:2)+1.5;
        if p(2)<TOL
            if p(1)<TOL
                cat = 'botl';
                idx = {1 2};
            elseif p(1)>pos(3)-TOL
                cat = 'botr';
                idx = {3 2};
            else
                cat = 'bottom';
                idx = {[] 2};
            end
        elseif p(2)>pos(4)-TOL
            if p(1)<TOL
                cat = 'topl';
                idx = {1 4};
            elseif p(1)>pos(3)-TOL
                cat = 'topr';
                idx = {3 4};
            else
                cat = 'top';
                idx = {[] 4};
            end
        else
            if p(1)<TOL
                cat = 'left';
                idx = {1 []};
            elseif p(1)>pos(3)-TOL
                cat = 'right';
                idx = {3 []};
            else
                disp('please click a border of object')
                return
            end
        end
        set(hf,'pointer',cat)
        fn_buttonmotion({@frameresizeborder,hf,hobj,idx,getvalue(info.scale)},hf)
        set(hf,'pointer','arrow')
    case 'extend'
        p0 = getvalue(info.scale)*round(p/getvalue(info.scale));
        set(hf,'pointer','hand')
        fn_buttonmotion({@frameresizemove,hf,hobj,p0,pos,getvalue(info.scale)},hf)
        set(hf,'pointer','arrow')
    case 'alt'
        pos = getvalue(info.scale)*(round(pos/getvalue(info.scale)));
        set(hobj,'position',pos);
end

%---
function frameresizeborder(hf,hobj,idx,scale)

pos = get(hobj,'position');
pos(3:4) = pos(3:4)+pos(1:2);
posf = get(hf,'position');
p = get(0,'pointerlocation')-posf(1:2);
p = scale*round(p/scale);
pos(idx{1}) = p(1);
pos(idx{2}) = p(2);
pos(3:4) = max(1,pos(3:4)-pos(1:2))
set(hobj,'position',pos)

%---
function frameresizemove(hf,hobj,p0,pos,scale)

posf = get(hf,'position');
p = get(0,'pointerlocation')-posf(1:2);
p = scale*round(p/scale);
pos(1:2) = pos(1:2)+(p-p0);
set(hobj,'position',pos)

%---
function movepanel(hp,pos0)

hf = get(hp,'parent');
switch get(hf,'SelectionType')
    case 'alt'
        set(hp,'position',pos0)
    otherwise
        set(hf,'pointer','hand')
        fn_moveobject(hp)
        set(hf,'pointer','arrow')
end

%---
function attachdata(hf,grob,fname)

setappdata(hf,'fn_framedesign',struct('grob',grob,'fname',fname))

%---
function s = flattenstruct(s,prefix,a)
% add elements of structure a to structure s with prefix added to field
% names

% "root" call with only one argument
if nargin==1
    F = fieldnames(s);
    for i=1:length(F)
        f = F{i};
        a = s.(f);
        if isstruct(a)
            s = rmfield(s,f);
            s = flattenstruct(s,[f '__'],a);
        end
    end
    return
end

% recursive call
F = fieldnames(a);
for j=1:length(F)
    f = F{j};
    b = a.(f);
    if isstruct(b)
        s = flattenstructure(s,[prefix f '__'],b);
    else
        s.([prefix f]) = b;
    end
end



