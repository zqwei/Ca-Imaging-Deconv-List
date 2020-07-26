function fn_figmenu(hf,varargin)
% function fn_figmenu
% function fn_figmenu(hf)
%---
% adds a custom menu to figure
%
% Note that function fn_figmenu makes use of fn_cd, and in order to be
% able to use it to save figures in the predefined directory 'capture',
% you should use 'fn_cd edit' to define where is this directory 'capture'.

% Thomas Deneux
% Copyright 2007-2017

if nargin==0
    hfs = findobj('type','figure');
    for hf = hfs'
        m = findall(hf,'tag','fn_figmenu');
        if isempty(m)
            m = uimenu(hf,'label','&Utils','Tag','fn_figmenu','handlevisibility','off'); 
        else
            delete(get(m,'children'))
        end
        setsubmenus(m,hf)
    end
else
    % check if figure is likely to be a dialog -> in such case, cancel the
    % menu creation
    if ~isempty(get(hf,'buttonDownFcn')), return, end
    m = uimenu(hf,'label','Utils','Tag','fn_figmenu','handlevisibility','off');
    setsubmenus(m,hf)
end

%---
function setsubmenus(m,hf)

uimenu(m,'label','tmp','Callback','tmp')
uimenu(m,'label','edit tmp','Callback','edit tmp')
uimenu(m,'label','edit fn_figmenu','Callback','edit fn_figmenu')

uimenu(m,'label','frame design','callback',@(u,e)fn_framedesign(hf),'separator','on')
uimenu(m,'label','get figure size','callback',@(u,e)figsize(hf))

uimenu(m,'label','fn_imvalue','Callback','fn_imvalue','separator','on')
uimenu(m,'label','fn_imvalue image','Callback','fn_imvalue image')
uimenu(m,'label','fn_imvalue end','Callback','fn_imvalue end')
m1 = uimenu(m,'label','more');
uimenu(m1,'label','fn_imvalue clean','Callback','fn_imvalue clean')
uimenu(m1,'label','fn_imvalue xy image','Callback','fn_imvalue xy image')
uimenu(m1,'label','fn_imvalue register ...','Callback','fn_imvalue register')
uimenu(m1,'label','fn_imvalue unregister','Callback','fn_imvalue unregister')

m1 = uimenu(m,'label','colormap');
uimenu(m1,'label','gray','Callback','colormap gray','separator','on')
uimenu(m1,'label','jet','Callback','colormap jet')
uimenu(m1,'label','mapclip','Callback','colormap mapclip')
uimenu(m1,'label','signcheck','Callback','colormap signcheck')
uimenu(m1,'label','green','Callback','colormap green')

uimenu(m,'label','reset figure callbacks', ...
    'Callback', ...
    'set(gcf,''WindowButtonMotionFcn'','''',''WindowButtonUpFcn'','''',''KeyPressFcn'','''')', ...
    'separator','on')

uimenu(m,'label','fn_clipcontrol','Callback','fn_clipcontrol','separator','on')
uimenu(m,'label','fn_imdistline','Callback','fn_imdistline')

items.savedefmenu = uimenu(m,'label','save SVG','separator','on', ...
    'callback',@(u,evnt)savefig(hf,'default'));
m1 = uimenu(m,'label','save PDF');
uimenu(m1,'label','scale 1', ...
    'callback',@(u,evnt)savefig(hf,'PDF',1));
uimenu(m1,'label','scale 0.9', ...
    'callback',@(u,evnt)savefig(hf,'PDF',.9));
uimenu(m1,'label','scale 0.8', ...
    'callback',@(u,evnt)savefig(hf,'PDF',.8));
uimenu(m1,'label','scale 0.7', ...
    'callback',@(u,evnt)savefig(hf,'PDF',.7));
uimenu(m1,'label','scale 0.6', ...
    'callback',@(u,evnt)savefig(hf,'PDF',.6));
uimenu(m1,'label','scale 0.5', ...
    'callback',@(u,evnt)savefig(hf,'PDF',.5));
uimenu(m,'label','save figure (select file)...', ...
    'callback',@(u,evnt)savefig(hf,'askname'))
uimenu(m,'label','copy figure to clipboard', ...
    'callback',@(u,evnt)savefig(hf,'clipboard'))
uimenu(m,'label','copy figure (no buttons)', ...
    'callback',@(u,evnt)copyfigure(hf,'nobutton'))
m1 = uimenu(m,'label','More');
uimenu(m1,'label','white background', ...
    'callback',@(u,evnt)set(hf,'color','white'))
uimenu(m1,'label','save figure (full options)...', ...
    'callback',@(u,evnt)fn_savefig(hf))
uimenu(m1,'label','append to ps file...', ...
    'callback',@(u,evnt)savefig(hf,'append'))
uimenu(m1,'label','append to ps file and make pdf...', ...
    'callback',@(u,evnt)savefig(hf,'append+pdf'))
uimenu(m1,'label','make pdf...', ...
    'callback',@(u,evnt)savefig(hf,'ps2pdf'))
uimenu(m1,'label','copy figure (with buttons)', ...
    'callback',@(u,evnt)copyfigure(hf))
uimenu(m1,'label','copy sub-part...', ...
    'callback',@(u,evnt)fn_savefig(hf,'showonly','subframe'))
uimenu(m1,'label','magnify current axes', ...
    'callback',@(u,evnt)copypart(hf,'current axes'))
uimenu(m1,'label','copy image to clipboard', ...
    'callback',@(u,evnt)saveimage(hf,'clipboard'))
uimenu(m1,'label','save image to png...', ...
    'callback',@(u,evnt)saveimage(hf,'png'))

setappdata(hf,'fn_figmenu',items)

%---
function figsize(hf)

pos = get(hf,'pos');
% fprintf('figure size: %i %i %i %i, set(%i,''pos'',[%i %i %i %i])\n',pos,hf,pos)
if isnumeric(hf), fignum=hf; else fignum=get(hf,'Number'); end
fprintf('figure size: %i %i %i %i, fn_setfigsize(%i,%i,%i) %%\n',pos,fignum,pos(3:4))
clipboard('copy',sprintf('[%i %i]',pos(3:4)))

%---
function savefig(hf,flag,varargin)

items = getappdata(hf,'fn_figmenu');
switch flag
    case 'default'
        if isfield(items,'savedef')
            fn_savefig(hf,items.savedef{:})
        else
            fn_savefig(hf,'autoname','svg')
        end
    case 'PDF'
        fn_savefig(hf,'autoname','pdf','scaling',varargin{1})
        items.savedef = {'autoname','pdf','scaling',varargin{1}};
        setappdata(hf,'fn_figmenu',items)
        set(items.savedefmenu,'label',['save PDF - scale ' num2str(varargin{1})])
    case 'askname'
        if isnumeric(hf), fignum=hf; else fignum=get(hf,'Number'); end
        fname = fn_savefile( ...
            '*.png;*.PNG;*.bmp;*.BMP;*.jpg;*.JPG;*.eps;*.EPS;*.ps;*.PS;*.pdf;*.PDF;*.fig;*.FIG', ...
            ['Select file where to save figure ' num2str(fignum)]);
        if isequal(fname,0), return, end
        fn_savefig(hf,fname)
        % memorize action
        items.savedef = {fname};
        setappdata(hf,'fn_figmenu',items)
        set(items.savedefmenu,'label',['save to ' fn_fileparts(fname,'name')])
    case {'append' 'append+pdf'}
        fname = fn_getfile('*.ps',['Select ps file where to append figure ' num2str(hf)]);
        if isequal(fname,0), return, end
        fn_savefig(hf,fname,flag)
        % memorize action
        items.savedefname = {fname,'append'};
        setappdata(hf,'fn_figmenu',items)
        set(items.savedefmenu,'label',['append to ' fn_fileparts(fname,'base') '.ps'])
    case 'ps2pdf'
        fname = fn_getfile('*.ps','Select ps file to convert to pdf');
        fn_savefig(hf,fname,'ps2pdf');
    case 'clipboard'
        x = getframe(hf);
        x = x.cdata;
        isbgcol = all(fn_eq(x,x(1,1,:)),3);
        idx = find(~all(isbgcol,1)); x = x(:,idx(1):idx(end),:);
        idx = find(~all(isbgcol,2)); x = x(idx(1):idx(end),:,:);
        imclipboard('copy',x)
end

%---
function saveimage(hf,flag)

im = flipud(findobj(hf,'type','image')); % from first to last created, this is more natural
if isempty(im)
    errordlg('no image found in figure')
    return
elseif ~isscalar(im)
    n = length(im);
    cdata = get(im,'cdata');
    desc = cell(1,n);
    for i=1:n
        ci = cdata{i};
        desc{i} = [fn_strcat(size(ci),'*') ' ' class(ci)];
    end
    [selection ok] = listdlg('PromptString','Which image do you want to save?', ...
        'ListString',desc,'SelectionMode','single');
    if ~ok, return, end
    im = im(selection);
end
cdata = get(im,'cdata');

if isa(cdata,'single'), cdata = double(cdata); end
if size(cdata,3)==1
    cm = get(hf,'colormap');
    ha = get(im,'parent');
    clip = get(ha,'clim');
    cdata = fn_clip(cdata,clip,cm);
end

switch flag
    case 'clipboard'
        imclipboard('copy',cdata)
    case 'png'
        fname = fn_savefile('*.png','Select file where to save image.');
        imwrite(cdata,fname)
end

%---
function copypart(hf,flag)

hv = get(hf,'handlevisibility');
set(hf,'handlevisibility','on'), ha = gca; set(hf,'handlevisibility',hv)
if fn_parentfigure(ha)~=hf, errormsg 'select axes first', return, end

switch flag
    case 'current axes'
        hf1 = figure;
        set(hf1,'color',get(hf,'color'))
        ha1 = copyobj(ha,hf1);
        set(ha1,'units','normalized','position','default')
        fn_set(findobj(ha1),'buttondownfcn','','createfcn','','deletefcn','')
end

%---
function copyfigure(hf,flag)

hf1 = copyobj(hf,0);
if nargin>=2 && strcmp(flag,'nobutton')
    delete(findall(hf1,'type','uicontrol'))
end
% handle Utils menu!
m = findall(hf1,'tag','fn_figmenu'); % there should be 2 of them!, keep only the last (older, linked to the new figure, not to the original one)
delete(m(1)), m(1)=[];
figname = get(hf,'name');
if isempty(figname), figname = ['(copy of Figure ' num2str(get(hf,'number')) ')']; else figname = [figname ' (copy)']; end
set(hf1,'tag','','name',figname, ...
    'WindowButtonDownFcn','','WindowButtonUpFcn','', ...
    'WindowButtonMotionFcn','','WindowKeyPressFcn','','WindowKeyReleaseFcn','', ...
    'WindowScrollWheelFcn','');
fn_set(setdiff(findall(hf1),findall(m)),'buttondownfcn','','deletefcn','', ...
    'keypressfcn','','keyreleasefcn','','callback','')
p = get(hf,'pos');
p0 = get(0,'screenSize');
H = 94; W = 20; % difference in width/height between figure outer and inner pos
if p(4)+H<p(2)
    p(2) = max(1,p(2)-p(4)-H);
elseif p(1)+p(3)+W<p0(3)-p(3)-W
    p(1) = min(p(1)+p(3)+W,p0(3)-p(3)-W);
else
    p(1) = p(1)+60;
    p(2) = p(2)-40;
end
set(hf1,'pos',p)


