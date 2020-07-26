function fn_imvalue(varargin)
% fn_imvalue [image] [xy|xonly]
% fn_imvalue clean
% fn_imvalue end
% fn_imvalue('chgx'|'chgy'|'chgxy',newax[,ha])
% fn_imvalue('register'[,ha][,command])
% fn_imvalue('unregister'[,ha])
% fn_imvalue demo
%---
% Link images with same dimensions via a crosshair pointer, prints
% values, and enable common zooming and translations.
% Link plots with same x-axis and enable common x-zooming and
% x-translations.
% To prevent conflicts with other programs, it does nothing in windows
% that contain objects with a 'Tag' or 'ButtonDown' property already set.
%
% At each click, i and j variable are created in the base workspace, and
% can be used, for example by the registered command.
% 
% When an axes is clicked, its 'UserData' property is changed, such that
% user can add additional callbacks to the same axes by using a listener
% ('addlistener(ha,'UserData','PostSet',fun_handle)') - don't use the axes
% 'ButtonDownFcn' property as it is already used by fn_imvalue.

% Thomas Deneux
% Copyright 2003-2017

if nargin>0 && fn_ismemberstr(varargin{1}, ...
        {'clean','end','chgx','chgy','chgxy','register','unregister','demo'})
    if strcmp(varargin{1},'end'), varargin{1}='terminate'; end
    if ~isappdata(0,'fn_imvalue')
        switch varargin{1}
            case {'clean','end'}
                % nothing to do 
                return
            case {'chgx','chgy','register','unregister'}
                error('fn_imvalue not initialized yet, run ''fn_imvalue'' first')
        end
    end
    feval(varargin{:})
else
    [axisimage xonly xy] = fn_flags('image','xonly','xy',varargin);
    if xonly && xy, error('specifying ''xonly'' and ''xy'' flags is contradictory'), end
    init(axisimage,~xy)
end

%-----------
% User calls
%-----------
function init(axisimage,xonly)

set(0,'DefaultImageCreateFcn',{@imv_initAxesChildren})
set(0,'DefaultLineCreateFcn',{@imv_initAxesChildren})

infobase.axisimage = axisimage;
infobase.xonly = xonly;
setappdata(0,'fn_imvalue',infobase)

for ha = findobj('type','axes')'
    initAxes(ha,'')
end

%-----------
function terminate

set(0,'DefaultImageCreateFcn','')
set(0,'DefaultLineCreateFcn','')
if isappdata(0,'fn_imvalue')
    rmappdata(0,'fn_imvalue')
end
for ha = findobj('type','axes')'
    if strcmp(get(ha,'Tag'),'fn_imvalue')
        terminateAxes(ha)
    end
end

%-----------
function clean

delete(findobj(0,'Tag','ImValText'))
delete(findobj(0,'Tag','ImValCross'))

%-----------
function chgx(newax,hObject)

if nargin==1, hObject = gca; end
ax = axis(hObject);
newax = [newax(:)' ax([3 4])];
chgxy(newax,hObject)

%-----------
function chgy(newax,hObject)

if nargin==1, hObject = gca; end
ax = axis(hObject);
newax = [ax([1 2]) newax(:)'];
chgxy(newax,hObject)

%-----------
function chgxy(newax,hObject)
% manually change the axis in a graph and its linked graphs

if nargin==1, hObject = gca; end
info = getappdata(hObject,'fn_imvalue');
oldax = info.OldAxis;
isimg = info.IsImg;
hlist = linkedAxes(oldax,isimg);
for ha=hlist, chgAxis(ha,newax), end

%---
function demo

C = {'fn_imvalue image'
    'figure(1), clf, colormap gray'
    'load trees'
    'subplot(221), imagesc(X)'
    'subplot(222), imagesc(-X)'
    'nt = 100;'
    't = linspace(0,3,nt);'
    'signal = sin(2*pi*t);'
    'subplot(223), plot(t,signal)'
    'subplot(224), plot(t,signal+rand(1,nt))'};
fn_dispandexec(C{:})

%-------------------------
% Init and Terminate Axes
%-------------------------

function initAxes(hObject,type)

% infobase should already be initialized; info should be only if fn_imvalue
% was already active on this axes
infobase = getappdata(0,'fn_imvalue');
info = getappdata(hObject,'fn_imvalue');

% tant que les propri�t�s de l'axes (buttondownfcn, tag...) ne sont pas
% modifi�es par un nouveau 'plot' ou 'image' en 'hold off', plus besoin des
% appels automatiques � 'fn_imvalue'


% actions to perform if this axes was already registered
if ~isempty(info) 
    if info.IsImg 
        if strcmp(type,'image')
            % (first delete old object as they can cause the axis to extend
            % beyond the image position)
            delete(findobj(get(hObject,'children'),'Tag','ImValCross'))
            delete(findobj(get(hObject,'children'),'Tag','ImValText'))
            if infobase.axisimage
                axis(hObject,'image')
            else
                axis(hObject,'normal')
            end
        else
            if ishandle(info.ydirlistener), delete(info.ydirlistener), end
            info.ydirlistener = [];
        end
    end
end

% cancel call to fn_imvalue for next lines created in the same axes to
% avoid multiple call when a large number of lines are created
% note that when calling 'plot' function, since the axes properties are
% reset, the automatic call to fn_imvalue will be active again
set(hObject,'DefaultLineCreateFcn','')

% strangely, this is not the case for calls to 'image' function, so better
% leave the automatic calling feature untouched (all the more since it is
% quite rare that a large number of image objects are created)

% set(hObject,'DefaultImageCreateFcn','')

% s'il y a d�j� un callback ou un Tag dans cet axes provenant d'une autre application, 
% ou si on est dans un display 3D, ne rien faire
if ~strcmp(get(hObject,'Tag'),'fn_imvalue') % le plus probable ; plus rapide de d'abord tester ��
    if length(axis(hObject))==6 
        return
    end 
    hc = [get(hObject,'parent') ; hObject]'; % ; get(hObject,'children')]';
    for h = hc
        if ~isempty(get(h,'ButtonDownFcn')) || ~isempty(get(h,'Tag'))
            return
        end
    end
end

% build the info, set the callback
hc = get(hObject,'children');
info.oldtag = get(hObject,'Tag');
set(hObject,'Tag','fn_imvalue')
setHitTestOff(hObject);
oldax = axis(hObject);
set(hObject,'ButtonDownFcn',{@imv_buttonDown})
isimg = any(strcmp(get(hc,'type'),'image'));
if isimg && infobase.axisimage, axis(hObject,'image'), end
info.IsImg = isimg;
hlist = linkedAxes(oldax,isimg,1);
if isempty(hlist)
    if isimg
        newpoint = get(hObject,'CurrentPoint'); 
        newpoint = newpoint([1 3]); 
        newpoint = min(max(newpoint,oldax([1 3])),oldax([2 4]));
    end
    newax = oldax;
else
    info1 = getappdata(hlist(1),'fn_imvalue');
    if isimg
        if ~isfield(info1,'ImPoint')
            warning('there is a bug here, should be fixed') %#ok<WNTAG>
            newpoint = [];
        else
            newpoint = info1.ImPoint;
        end
        if isempty(newpoint), newpoint = get(hObject,'CurrentPoint'); newpoint = newpoint([1 3]); end
    end
    newax = info1.CurrentAxis;
end
info.OldAxis = oldax;
% field for user function
if ~isfield(info,'register'), info.register = []; end

% detect change of y direction
if isimg && ~isfield(info,'ydirlistener') % do not create a redundant listener, in case axes had already been registered before
    info.ydirlistener = addlistener(hObject,'YDir','PostSet',@(hu,e)chgAxis(hObject,'ydir'));
end

% save info
setappdata(hObject,'fn_imvalue',info);

% update display
if isimg
    chgValue(hObject,newpoint)
    chgAxis(hObject,newax)
else
    set(hObject,'xlim',newax(1:2))
    info.CurrentAxis=[newax(1:2) oldax(3:4)];
    setappdata(hObject,'fn_imvalue',info);
end


%-----------
function terminateAxes(hObject)

setHitTestBack(hObject)
set(hObject,'ButtonDownFcn','')

info = getappdata(hObject,'fn_imvalue');

if ~isempty(info)
    axis(hObject,info.OldAxis)
    set(hObject,'Tag',info.oldtag)
    rmappdata(hObject,'fn_imvalue')
    if info.IsImg, delete(info.ydirlistener), end
else
    disp('strange, info is empty...')
    if fn_debug, keyboard, end
    set(hObject,'Tag','')
end

hc = get(hObject,'children');
delete(union(findobj(hc,'Tag','ImValText'),findobj(hc,'Tag','ImValCross')))

%-----------
% Tools functions
%-----------
function setHitTestOff(ha,varargin)

set(ha,'DefaultLineHitTest','off');
set(ha,'DefaultImageHitTest','off');
set(ha,'DefaultPatchHitTest','off');

for ho=get(ha,'children')'
    setappdata(ho,'OldHitTest',get(ho,'HitTest'))
    set(ho,'HitTest','off')
end

%-----------
function setHitTestBack(ha,varargin)

set(ha,'DefaultLineHitTest',get(get(ha,'parent'),'DefaultLineHitTest'));
set(ha,'DefaultImageHitTest',get(get(ha,'parent'),'DefaultImageHitTest'));
set(ha,'DefaultPatchHitTest',get(get(ha,'parent'),'DefaultPatchHitTest'));

for ho=get(ha,'children')'
    if isappdata(ho,'OldHitTest')
        set(ho,'HitTest',getappdata(ho,'OldHitTest'))
    else
        set(ho,'HitTest','on') %...
    end
end

%-----------
function updateAxes(hObject)
% check if axis(hObject) has been changed meanwhile by user or by Matlab
% -> update oldaxis and currentaxis properties if necessary

info = getappdata(hObject,'fn_imvalue');

info0 = getappdata(0,'fn_imvalue');
if info0.xonly, idx = 1:4; else idx = 1:4; end % ?

if isempty(info), return, end
curaxis = info.CurrentAxis;
ax = axis(hObject);
if length(ax)~=4, rmappdata(hObject,'fn_imvalue'), return, end

if ~info.IsImg && any(ax(3:4)~=curaxis(3:4)) && ~any(ax(1:2)~=curaxis(1:2))
    info.OldAxis(3:4)=ax(3:4);
    info.CurrentAxis=ax;
    setappdata(hObject,'fn_imvalue',info)
elseif any(ax~=curaxis)
    %disp('fn_imvalue: external change in axis, error might occur')
    info.OldAxis(idx)=ax(idx);
    info.CurrentAxis=ax;
    setappdata(hObject,'fn_imvalue',info)
end

%-----------
function ret = linkedAxes(refaxis,isimg,onlyone)

if nargin<3, onlyone = false; end
ret = [];
if isimg, interest = 1:4; else interest = 1:2; end
for ha = findallaxes
    info1 = getappdata(ha,'fn_imvalue');
    if isempty(info1), continue, end
    oldaxis = info1.OldAxis;
    if all(oldaxis(interest)==refaxis(interest))
        if onlyone
            ret = ha; return
        else
            ret = [ret ha];
        end  
    end
end


%-----------
function ha = findallaxes(hp)

if nargin==0
    ha = [];
    panels = row(allchild(0)); % figures
else
    c = row(allchild(hp));
    ctype = get(c,'type');
    ha = c(strcmp(ctype,'axes'));
    panels = c(strcmp(ctype,'uipanel'));
end
npanel = length(panels);
if npanel
    ha2 = cell(1,npanel);
    for i=1:npanel
        ha2{i} = findallaxes(panels(i));
    end
    ha = [ha ha2{:}];
end




%-----------
function chgAxis(hObject,newax)

info = getappdata(hObject,'fn_imvalue');
infobase = getappdata(0,'fn_imvalue');

if info.IsImg
    if ~strcmp(newax,'ydir'), axis(hObject,newax), end % it can happen that no newax is defined, in the case we just want to re-draw the value
    ht = findobj(get(hObject,'children'),'Tag','ImValText');
    if ishandle(ht)
        val = get(ht,'String');
        delete(ht)
        createValText(hObject,val);
        info.ImValText = ht;
    else
        createValText(hObject,info.ImPoint);
    end
    if nargin<2, return, end
    cross(hObject)
else
    if strcmp(newax,'ydir')
        disp 'ydirlistener still active? check this'
        return
    end
    ax = axis(hObject);
    if infobase.xonly
        axis(hObject,[newax(1:2) ax(3:4)])
    else
        axis(hObject,newax)
    end
end
info.CurrentAxis = axis(hObject);

setappdata(hObject,'fn_imvalue',info)

%-----------
function chgValue(hObject,newpoint)

info = getappdata(hObject,'fn_imvalue');
info.ImPoint = newpoint;
setappdata(hObject,'fn_imvalue',info)

ht = findobj(get(hObject,'children'),'Tag','ImValText');
if ishandle(ht)
    set(ht,'String',getValue(hObject,newpoint))
else
    createValText(hObject,newpoint);
end
cross(hObject)

% user function 
if ~isempty(info.register), evalregister(hObject), end

%-----------
function str = getValue(hObject,point)

hi = findobj(get(hObject,'children'),'type','image');
if length(hi)~=1, str=''; return, end
im = get(hi,'CData');
[ni nj ncol] = size(im); %#ok<NASGU>

info = getappdata(hObject,'fn_imvalue');
oldaxis = info.OldAxis;
x0 = oldaxis(1); xrange = oldaxis(2)-x0;
y0 = oldaxis(3); yrange = oldaxis(4)-y0;
j = round( point(1)*nj/xrange - nj*x0/xrange + .5 );
i = round( point(2)*ni/yrange - ni*y0/yrange + .5 );
if i>0 && i<=ni && j>0 && j<=nj
    val = shiftdim(im(i,j,:),1);
    str = [sprintf('val(%i,%i) =',i,j) sprintf(' %.5g',val)];
else
    str = '';
end

%-----------
function createValText(hObject,pointorvalue)

val = pointorvalue;
if ~ischar(val)
    try
        val = getValue(hObject,pointorvalue);
    catch
        return
    end
end
ax = axis(hObject);
switch get(hObject,'ydir')
    case 'normal'
        ptext = ax([1 3]) + [0 1.03].*(ax([2 4])-ax([1 3]));
    case 'reverse'
        ptext = ax([1 3]) + [0 -0.04].*(ax([2 4])-ax([1 3]));
end
text('Parent',hObject,'Position',ptext,'String',val,'Tag','ImValText');

%-----------
function cross(hObject)   

delete(findobj(get(hObject,'children'),'Tag','ImValCross'))
info = getappdata(hObject,'fn_imvalue');
point = info.ImPoint;
ax = axis(hObject);
line([point(1) point(1)],[ax(3) ax(4)],'Parent',hObject, ...
    'Color','black','Tag','ImValCross','HitTest','off','CreateFcn','');
line([ax(1) ax(2)],[point(2) point(2)],'Parent',hObject, ...
    'Color','black','Tag','ImValCross','HitTest','off','CreateFcn','');

%-----------
% Callback calls
%-----------
function imv_initAxesChildren(hObject,dum)

ha = get(hObject,'parent');
if ~strcmp(get(ha,'type'),'axes'), return, end
type = get(hObject,'type');
% (try to) initialize axes
initAxes(ha,type)

%-----------
function imv_buttonDown(hObject,dum)

% validate user and Matlab automatic changes in all axis ranges
hlist = findobj('type','axes');
for ha=hlist', updateAxes(ha), end

info = getappdata(hObject,'fn_imvalue');
infobase = getappdata(0,'fn_imvalue');

hf = fn_parentfigure(hObject);
selectiontype = get(hf,'SelectionType');

isimg = info.IsImg;
oldax = info.OldAxis;
hlist = linkedAxes(oldax,isimg);

switch selectiontype
    case 'normal'
        rect = fn_mouse(hObject,'rect-');
        rectpixsize = abs(fn_coordinates(hObject,'a2b',rect(3:4),'vector'));
        if all(rectpixsize>2)                                               % zoom to selection
            newax = [rect(1) (rect(1)+rect(3)) rect(2) (rect(2)+rect(4))];
            if isimg || ~infobase.xonly
                newax = [max(newax(1),oldax(1)) min(newax(2),oldax(2)) max(newax(3),oldax(3)) min(newax(4),oldax(4))];
                if newax(1)>=newax(2), newax(1:2)=oldax(1:2); end
                if newax(3)>=newax(4), newax(3:4)=oldax(3:4); end
            else
                newax = [max(newax(1),oldax(1)) min(newax(2),oldax(2)) newax(3:4)];
                if newax(1)>=newax(2), newax(1:2)=oldax(1:2); end
            end
            
            for ha = hlist, chgAxis(ha,newax), end
            % if it is a plot, only the x axis is changed everywhere
            % however we want also to change the y axis as the user specified in
            % the current axes
            if ~isimg
                axis(hObject,newax)
                info.CurrentAxis = axis(hObject);
                setappdata(hObject,'fn_imvalue',info)
            end
        else
            newpoint = get(hObject,'CurrentPoint');
            newpoint = newpoint([1 3]);
            if isimg                                                        % move cross
                ax = axis(hObject);
                centre = mean(ax([1 3 ; 2 4]));
                window = diff(ax([1 3 ; 2 4]));
                disttoedge = 1/2 - abs(newpoint-centre)./window;
                if any(disttoedge<.05)                      % shift
                    shift = min(max(newpoint-centre,oldax([1 3])-ax([1 3])),oldax([2 4])-ax([2 4]));
                    newax = ax + kron(shift,[1 1]);
                    for ha = hlist, chgAxis(ha,newax), end
                end
                % display value
                for ha = hlist, chgValue(ha,newpoint), end
            else                                            % shift left or right
                ax = axis(hObject);
                width = ax(2)-ax(1);
                newxstart = newpoint(1)-width/2;
                newax = [newxstart (newxstart+width) ax(3:4)];
                for ha = hlist, chgAxis(ha,newax), end
            end
        end
    case 'alt'                                                              % zoom out (reset)
        newax = oldax;
        if ~isimg, axis(hObject,newax), end
        for ha = hlist, chgAxis(ha,newax), end
    case 'extend'                                                           % zoom out (2x)
        ax = axis(hObject);
        newax = 2*ax - ax([2 1 4 3]);
        newax = [max(newax([1 3]),oldax([1 3])) min(newax([2 4]),oldax([2 4]))];
        newax = newax([1 3 2 4]);
        if ~isimg, axis(hObject,newax), end
        for ha = hlist, chgAxis(ha,newax), end
    case 'open'
        % no action
end

% change 'UserData' property to allow a listener to catch the event
set(ha,'UserData',rand)

%-----------
% Register additional actions
%-----------

function register(varargin)

% input
ha = gca; str = [];
for i=1:nargin
    a = varargin{i};
    if ishandle(a)
        switch get(a,'type')
            case 'figure'
                hc = get(a,'children');
                hc = hc(strcmp(get(hc,'type'),'axes'));
                if length(hc)~=1, error('figure has no, or too many, axes'), end
                ha = hc;
            case 'axes'
                ha = a;
            otherwise
                error('wrong handle')
        end
    else
        str = a;
    end
end
info = getappdata(ha,'fn_imvalue');
if ~info.IsImg
    disp('no registration possible for plots')
    return
end
if isempty(str)
    str = input('enter callback (use i,j): ','s');
end

% evaluate command and check if it creates a new figure
allf = get(0,'children');
if ~isempty(info.register), allf = setdiff(allf,info.register.hf); end
set(allf,'handlevisibility','off')
assignin('base','i',round(info.ImPoint(2)))
assignin('base','j',round(info.ImPoint(1)))
try    
    evalin('base',str)
    hf = get(0,'children'); 
    if length(hf)>1, error('command should use at most one figure'), end
catch
    set(allf,'handlevisibility','on')
    disp('error when executing string: registration failed')
    return
end
set(allf,'handlevisibility','on')

% save
info.register = struct('cmd',str,'hf',hf);
setappdata(ha,'fn_imvalue',info)

%---
function unregister(hlist)

if nargin<1, hlist = findobj('type','axes')'; end

for ha = hlist
    info = getappdata(ha,'fn_imvalue');
    if ~isempty(info) && ~isempty(info.register)
        close(info.register.hf)
        info.register = [];
        setappdata(ha,'fn_imvalue',info)
    end
end

%---
function evalregister(hObject)

% avoid recursions
evaluating = getappdata(hObject,'fn_imvalue_evalregister');
if ~isempty(evaluating), return, end

info = getappdata(hObject,'fn_imvalue');
s = info.register;
if isempty(s), return, end
if ~info.IsImg, error programming, end
try
    assignin('base','i',round(info.ImPoint(2)))
    assignin('base','j',round(info.ImPoint(1)))
    scf = gcf;
    if ~isempty(s.hf), set(0,'currentfigure',s.hf), end
    setappdata(hObject,'fn_imvalue_evalregister',true);
    evalin('base',s.cmd)
    rmappdata(hObject,'fn_imvalue_evalregister');
    if ~isempty(s.hf), set(0,'currentfigure',scf), end
catch %#ok<CTCH>
    try rmappdata(hObject,'fn_imvalue_evalregister'); end %#ok<TRYNC>
    disp('error when executing command: cancel registration')
    info.register = [];
    setappdata(hObject,'fn_imvalue',info)
end





