function varargout = fn_4Dview(varargin)
% function fn_4Dview(option1,optionArgs1,...)
% function varargout = fn_4Dview(action,actionArgs)
%---
% displays spatial or temporal slices of multi-dimensional data
% by default: data is considered to be 3D, 4D or 5D (dimensions ordered as
% x-y-z-t-m) and is displayed as 3 spatial sections at a given time point
% use option flags for other display types
%
% type 'fn_4Dview demo' to see a demo
%
% Input:
% - option..        string - specify an option (see below)
% - optionArgs..    argument of option
% - action..        specific usage of fn_4Dview, does not create a new
%                   interface (see below)
%
% Options:
% DATA
% - 'data',data     array, by default, dimensions should be x - y - z - t - m 
%                   (m is used for multiple data or channels)   
%                   [the 'data' flag can be omitted]
%                   [default: data=0 or zeros(appropriate size)]
% - 'options',{options}     some display types allow additional options like 
%                   'xxxplot' -> same option possibilities as the Matlab plot function, 
%                   'quiver'...     
%                   [the 'options' flag can be omitted] [default: {}]
% TYPE OF DISPLAY
% - '3d'            data is three-dimensional (dimensions are x - y - z - t - m)
%                   and will be spatially displayed as three cross
%                   sections, for a given time point
%                   [default]
% - '3dplot'        data is three-dimensional (dimensions are x - y - z - t - m)
%                   and will be temporally displayed as a time course, for
%                   a given space point
% - '2d'            data is two-dimensional (dimensions are x - y - t - m)
%                   and will be spatially displayed as a single image
% - '2dplot'        data is two-dimensional (dimensions are x - y - t - m)
%                   and will be displayed temporally
% - '0d',tidx       [deprecated]
% - 'quiver'        data is a 2D vector field, plus possibly 2D image
%                   (dimensions are x - y - t - [2 vector components +
%                   image component])
%                   this is only applicable for spatial display
% - 'mesh',mesh     data is one-dimensional (dimensions are i - t - m),
%                   where i refers to the ith vertex of a 3D mesh specified
%                   as a cell array or struct following the 'mesh' flag 
%                   {[3 x nv vertices],[3 x nt triangles]},
%                   and will be spatially displayed as a surface
% - 'meshplot',mesh data is one-dimensional (dimensions are i - t - m) as
%                   for 'mesh', and will be displayed temporally
% - 'ind',indices   data is one-dimensional (dimensions are i - t - m),  
%                   indices is a 2D or 3D image which entails indices of
%                   the first data component (see example)
%                   this is only applicable for temporal display
% - 'timeslider',tidx   
%                   creates a slider control to move in time array tidx
% - 'ext',{@updatefcn,par1,par2,...}
%   'ext',{'command','infoname'}
%                   fn_4Dview does not display anything, but it links the
%                   execution of function updatefcn to other objects
%                   handled by fn_4Dview. The function prototype should be:
%                       updatefcn = function(info,par1,par2,...)
%                   with info being the structure described in fn_4Dview code.
%                   Alternatively, one can use a string command; each time
%                   before the command is executed, info is stored in the
%                   base workspace with the name 'infoname', so that the
%                   command can access to the informations it encloses.
%                   Attention, the information concerning these updates
%                   needs to be stored in a graphical object; if none is
%                   specified (using 'in'), one is automatically created,
%                   but one should delete it later on using 'fn_4Dview
%                   unregister' (see below)
% BEHAVIOR
% - 'active'        allows callbacks (e.g. selecting point with mouse) [default]
% - 'passive'       disallows callbacks
% - 'key',k         use this to have independent links between windows
%                   [default: all windows are linked using same key k=1]
% DATA TRANSFORM
% - 'mat',M         defines a spatial linear transformation between
%                   data and world coordinates [default = eye(4)] (pixel
%                   indices start at 1)
%                   can be a 4x4 or 3x4 matrix (rotation+translation) or
%                   3x3 matrix (rotation only) or 3x1 vector (translation
%                   only) or 1x3,1x2,1x1 vector (special: scaling, first
%                   pixel at [0 0 0])
% - 'tidx',[t0 dt]  time of first frame and interval between successive
%                   frames [default: t0-=1, dt=1]
% - 'tidx',tidx     alternatively, one can define every sampling points 
%                   time coordinates (tidx should not have 2 elements);
%                   it is necessary that they are equally spaced then
% - 'heeginv',H     provides a matrix to multiply data with before using it
%                   this is only applicable for spatial mesh display
% - 'applyfun',fun  function handler or {function handler, additional arguments, ...}
%                   data will be transformed according to fun before every
%                   display - NOT IMPLEMENTED YET
% DISPLAY
% - 'in',handle     forces display in figure, axes or uicontrol specified by handle
%                   [the 'in' flag can be ommited] 
%                   [default: in active figure or axes]
% - 'channel',f       if data has a 'multiple data' component (dimension m is
%                   non-singleton), specifies which one to use for spatial
%                   display [default: f=1]
% - 'clip',[m M]    specify a clipping for image display
% - 'xyzperm',[a b c] defines a permutation of the dimensions before
%                   visualizing the 3 cross-sections of the data
% - 'zfact',r       ratio between z and xy resolutions for 3D display
% - 'labels',{xlabel,ylabel,zlabel} axis labels (ylabel and zlabel can be omitted)
%
% Actions:
% - 'demo'                  run the demo
% - 'changexyz',key,xyz     update space coordinates for objects linked by the key       
% - 'changet',key,t         update time coordinate for objects linked by the key
% - 'unregister'[,@updatefcn][,key] 
%                           unregister external functions which were
%                           previously registered (type 'ext') by deleting
%                           the associated objects;
%                           this unregistration can be filtered by which
%                           function handles and/or which linking key
%
% How to use the mouse to select points and draw selections:
% - point with left button          -> change cursor
% - area with left button           -> zoom to region
% - double-click with left button   -> zoom reset
%   (or point with middle button outside of axis)
% - point/area with middle button   -> add point/area to current selection
% - double-click with middle button -> cancel current selection
%   (or point with middle button outside of axis)
% - point/area with right button    -> add new selection
% - double-click with right button  -> cancel all selections
%   (or point with right button outside of axis)

% Thomas Deneux
% Copyright 2004-2017
% last modification: September 20th, 2007

% try to execute action
firstchar = (nargin>0 && ischar(varargin{1}));
thirdchar = (nargin>2 && ischar(varargin{3})) ;
if firstchar || thirdchar
    if firstchar, ind=1; else ind=3; end
    a = varargin{ind};
    switch lower(a)
        case 'demo'
            demo, return
        case 'changexyz'
            ChangeXYZ(varargin{ind+1:end}), return
        case 'changet'
            ChangeT(varargin{ind+1:end}), return
        case 'register'
            hobj = Registering(varargin{ind+1:end}); 
            if nargout>0, varargout = {hobj}; end
            return
        case 'unregister'
            Unregister(varargin{ind+1:end}), return
    end
end

% otherwise create new object
Init(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Init(varargin)

if nargin==0, help fn_4Dview, return, end
indarg=1;

%-------
% Input
%-------

% Options
type='3d'; data=0; options={};
in=[]; key=1; active=true; 
Heeginv=[]; mat=eye(4); channel=1; t0=1; dt=1; ind=[]; mesh=[]; 
clip={}; xyzperm = [1 2 3]; zfact = 1; scale = [1 1 1]'; labels = {'x','y','z'};
while indarg<=nargin
    flag = varargin{indarg};
    if ischar(flag), indarg=indarg+1;
    elseif isfigoraxeshandle(flag), flag='in';
    elseif iscell(flag), flag='options';
    elseif isnumeric(flag), flag='data';
    else error('argument error')
    end
    flag = lower(flag);
    switch flag
        case 'data'
            data = varargin{indarg};
            indarg = indarg+1;
        case 'options'
            options = varargin{indarg};
            indarg = indarg+1;
        case 'space'
            error('specifying to show ''space'' is deprecated; remove the statement')
        case 'plot'
            error('specifying to show ''plot'' is deprecated; use type ''2dplot'' or ''3dplot'' instead')
        case 'time'
            error('specifying to show ''time'' is deprecated; use type ''2dplot'' or ''3dplot'' instead')
        case {'3d','3dplot','2d','2dplot'}
            type = flag;
        case 'quiver'
            type = 'quiver';
            data = varargin{indarg};
            indarg = indarg+1;
            nt = size(data,3);
            while indarg<=nargin && all(size(varargin{indarg})>1) % 2D or more array
                data2 = varargin{indarg};
                indarg = indarg+1;
                nt2 = size(data2,3);
                if nt2>1 && nt==1, data = repmat(data,[1 1 nt2]); end
                if nt>1 && nt2==1, data2 = repmat(data2,[1 1 nt]); end
                try data = cat(4,data,data2); catch, error('quiver data: dimensions are incommensurate'), end
            end
        case {'mesh','meshplot'}
            type = flag;
            if iscell(varargin{indarg})
                mesh = varargin{indarg};
                indarg = indarg+1;
            elseif isstruct(varargin{indarg})
                mesh = varargin{indarg};
                mesh = {mesh.vertices,mesh.faces};
                indarg = indarg+1;
            else
                mesh = {varargin{indarg},varargin{indarg+1}};
                indarg = indarg+2;
            end
            if size(mesh{1},1)~=3, mesh{1}=mesh{1}'; end
            if size(mesh{2},1)~=3, mesh{2}=mesh{2}'; end
        case 'ind'
            ind = varargin{indarg};
            indarg = indarg+1;
            type = 'indices';
        case 'timeslider'
            type = 'timeslider';
            tidx = varargin{indarg};
            data = tidx;
            t0 = tidx(1);
            switch length(tidx)
                case 1
                case 2
                    dt = tidx(2);
                otherwise
                    if any(abs(diff(diff(tidx)))>1e-7)
                        error('tidx: time points must be equally spaced')
                    end
                    dt = tidx(2)-t0;
            end
            indarg = indarg+1;
        case 'ext'
            type = 'ext';
            options = varargin{indarg};
            indarg = indarg+1;
        case {'active','passive'}
            active =  strcmp(flag,'active');
        case 'key'
            key = varargin{indarg};
            indarg = indarg+1;
        case 'tidx'
            tidx = varargin{indarg}; 
            t0 = tidx(1);
            switch length(tidx)
                case 1
                case 2
                    dt = tidx(2);
                otherwise
                    if any(abs(diff(diff(tidx)))>1e-7)
                        error('tidx: time points must be equally spaced')
                    end
                    dt = tidx(2)-t0;
            end
            indarg = indarg+1;
        case 'mat' 
            mat = varargin{indarg};
            indarg = indarg+1;
            switch num2str(size(mat),'%1i')
                case '44'
                case {'34','33'}
                    mat(4,4) = 1;
                case '31' % translation
                    mat = [eye(3) mat(:) ; 0 0 0 1];
                case {'13','12','11'} % special scaling
                    mat(end+1:3) = mat(end);
                    mat = [diag(mat) -mat'; 0 0 0 1];
                otherwise
                    error('wrong size for rotation/translation matrix')
            end
            scale = [norm(mat(1:3,1)) norm(mat(1:3,2)) norm(mat(1:3,3))]';
        case 'heeginv'
            Heeginv = varargin{indarg};
            indarg = indarg+1;
        case 'in'
            in = varargin{indarg}; 
            indarg = indarg+1; 
        case {'5th','fifth'}
            error('instruction ''fifth'' is deprecated, use ''channel'' instead')
        case 'channel'
            channel = varargin{indarg};
            indarg = indarg+1;
        case 'clip'
            clip = {varargin{indarg}};
            indarg = indarg+1;   
        case 'xyzperm'
            xyzperm = varargin{indarg};
            indarg = indarg+1;
        case 'zfact'
            zfact = varargin{indarg};
            indarg = indarg+1;
        case 'labels'
            labels = varargin{indarg};
            indarg = indarg+1;
            if ~iscell(labels), labels={labels}; end            
        otherwise
            error(['unknown option: ' flag])
    end
end

% Data and sizes
sizes = [];
switch type
    case {'2d','2dplot'} 
        % data dimensions should be ordered as: x-y-t-m -> transform into x-t-m
        sizes = size(data); sizes(end+1:4)=1; sizes = [sizes(1:2) 1 sizes(3:4)];
        data = reshape(data,[prod(sizes(1:3)) sizes(4:5)]);
    case {'3d','3dplot'}
        % data dimensions should be ordered as: x-y-z-t-m -> transform into x-t-m
        sizes = size(data); sizes(end+1:5)=1;
        data = reshape(data,[prod(sizes(1:3)) sizes(4:5)]);
    case 'quiver'
        % data dimensions should be ordered as: x-y-t-m and there may be several arguments
        % to be concatenated along 4th dimension -> transform into x-t-m
        sizes = size(data); sizes(end+1:4) = 1;
        if ~ismember(sizes(4),[2 3]), error('quiver: not enough data'), end
        data = reshape(data,[prod(sizes(1:2)) sizes(3:4)]);
    case {'mesh','meshplot'}
        % data dimensions should be ordered as: x-t-m
        sizes = size(data); 
        % no data given
        if all(sizes==1), data = zeros(size(mesh{1},2),1); sizes = size(data); end
        if isempty(Heeginv), scomp=sizes(1); else scomp=length(Heeginv*data(:,1)); end
        if scomp~=size(mesh{1},2), error('mesh: data dimension does not match number of vertices'), end
    case 'indices'
        % data dimensions should be ordered as: x-t-m
        nind = size(data,1);
        sizes = size(ind); sizes(end+1:3) = 1;
        maxind = max(ind(:));
        if maxind~=nind, disp('attention: maximum indice does not match data dimension'), end
    case 'timeslider'
        data = data(:)';
        sizes = [0 0 0];
    case 'ext'
        data = [];
        sizes = [0 0 0];
    otherwise 
        error programmation
end

%-------------------
% Other definitions
%-------------------

% Axis labels
switch length(labels)
    case 1
        labels = labels([1 1 1]);
    case 2
        if strcmp(type,'3d'), error('Z label not defined'), end
        labels{3} = '';
    case 3
    otherwise
        error('wrong number of axis label numbers')
end        

% Object (figure/axes/uicontrol) where information will be stored
try
    df = get(in,'DeleteFcn');
    if ischar(df), eval(df), else feval(df{:}), end
catch 
end
switch type
    case {'2dplot','3dplot','meshplot','2d','quiver'}
        if isempty(in)
            hobj = gca;
        elseif (in>0 && mod(in,1)==0)
            % create axes in the figure
            figure(in)
            hobj = axes('parent',in);
        elseif strcmp(get(in,'type'),'axes')
            hobj = in;
        else
            error('''in'' should be a figure or axes handle')
        end
        cla(hobj,'reset')
    case {'mesh','3d'}
        if isempty(in)
            hobj = gcf;
        elseif (in>0 && mod(in,1)==0)
            if ~ishandle(in), figure(in), end
            hobj = in;
        else
            error('''in'' should be a figure handle')
        end
        clf(hobj,'reset')
    case 'timeslider'
        % hobj can be a figure or an uicontrol
        if isempty(in)
            hobj = figure('visible','off');
        elseif length(in)==1 && ((in>0 && mod(in,1)==0) || strcmp(get(in,'type'),'figure'))
            if ~ishandle(in), figure(in), end
            hobj = in;
        elseif strcmp(get(in(1),'type'),'uicontrol')
            hobj = in(1);
            set(hobj,'style','slider')
            if length(in)==2, set(in(2),'style','text'), end
        else
            error('''in'' should be a figure or uicontrol handle')
        end
    case 'ext'
        if isempty(in)
            hobj = figure('visible','off','integerhandle','off');
        else
            hobj = in;
        end
end

% And the parent figure
hf = hobj; 
while ~strcmp(get(hf,'type'),'figure')
    hf = get(hf,'parent'); 
end
% remove existing callbacks and tag from this figure
set(hf,'WindowButtonDownFcn','','ResizeFcn','','WindowButtonMotionFcn','','Tag','');

%---------------------------
% Internal information
%---------------------------

info = struct('hobj', hobj,'hf',hf, ...
    ...                     DATA
    'data',data, ...            data: it is finally a 3D array (space x time x channel)
    'sizes',sizes, ...          size of data
    'nind',size(data,1), ...    number of space points (or 'indices')
    'nt',size(data,2), ...      number of time points
    'nchan',size(data,3), ...   number of channels
    'options',{options}, ...    additional data for quiver, plots, and exts
    ...                     TYPE OF DISPLAY
    'type',type, ...            type of data and of display
    'mesh',{mesh}, ...          definition of the mesh in case of mesh data
    ...                     BEHAVIOR
    'key',key, ...              object with same key are linked
    'active',active, ...        are the object callbacks active? (e.g. click in graph, ...)
    ...                     DATA TRANSFORM
    'mat',mat, ...              3x4 transformation matrix between indices and real world coordinates	[indice/world conversion]
    't0',t0, ...            	time of first frame
    'dt',dt, ...                time interval betweeen two frames
    'heeginv',Heeginv, ...      matrix to multiply data with
    'indices',ind, ...          TODO: update
    ...                     GENERAL DISPLAY
    'channel',channel, ...      which channel to display for spatial displays
    'clip',{clip}, ...          clipping range for spatial displays
    'xyzperm',xyzperm, ...      permutation of the spatial dimensions order with respect to standard display
    'zfact',zfact, ...          expansion (or reduction) of the 3rd displayed spatial dimension (TODO: replace by 3 factors)
    'scale', scale, ...         scales for the display of 3 spatial dimensions                          [indice/display conversion] 
    'labels',{labels}, ...      labels for the display of 3 spatial dimensions
    ...                     CURRENT DISPLAY
    'xyzt',[1 1 1 1], ...       current real world coordinates
    'xyzselection',{{}}, ...    current selection of points or sub-surfaces / sub-volumes
    'tselection',{{}}, ...      current selection of time intervals
    'haschanged',struct('xyz',true,'t',true,'xyzselection',true, ...
        'tselection',true,'plotaxis',true), ... does the display need to be updated?
    'ind',[], ...               current spatial global index
    'ijk',[], ...               current spatial indices vector
    'ijk2',[], ...              current spatial indices vector (not rounded to an integer)
    'frame',[], ...             current frame
    'indselection',{{}}, ...    current selection of indices (cell array of vectors)
    'frameselection',[] ...     current selection of frames (only one vector)
    );
setappdata(hobj,'fn_4Dview',info)

% Tag (used in functions Linked and Unregister)
set(hobj,'Tag','fn_4Dview')
if hobj~=hf, set(hf,'Tag','used by fn_4Dview'), end

%----------
% Display
%----------

% Figure display and callbacks
switch type
    case 'timeslider'
        InitTimeSlider(in)
    case {'2dplot','3dplot','meshplot'}
        InitPlotAxes(hobj)
    case '2d'
        Init2DAxes(hobj)
    case 'quiver'
        InitQuiverAxes(hobj)
    case '3d'
        Init3DFigure(hobj)
    case 'mesh'
        InitMeshFigure(hobj)
    case 'ext'
    otherwise
        error programming
end

% Update cursor position (TODO: update also zoom)
set(hobj,'Tag','')
info = getappdata(hobj,'fn_4Dview');
hlist = Linked(key);
if ~isempty(hlist)
    info0 = getappdata(hlist(1),'fn_4Dview');
    info.xyzt = info0.xyzt;
    info.xyzselection = info0.xyzselection;
    info.tselection = info0.tselection;
end
setappdata(hobj,'fn_4Dview',info);
Update(hobj)
set(hobj,'Tag','fn_4Dview')

%---------------------------------------------------------------------
function Init2DAxes(ha)

set(get(ha,'Parent'),'DoubleBuffer','on')

info = getappdata(ha,'fn_4Dview');
s = info.sizes;
xyperm = info.xyzperm(1:2);
if ~isempty(setxor(xyperm,[1 2])), error('problem with x-y permutation'), end
s = s(xyperm);
scale = info.scale(xyperm);
ticks = {(0:s(1)-1)*scale(1),(0:s(2)-1)*scale(2)};
labels = info.labels(xyperm);

hi = imagesc(ticks{1},ticks{2},zeros(s(1),s(2))','Parent',ha,'hittest','off',info.clip{:});
if all(s(1:2)>1), axis(ha,'image'), end
xlabel(ha,labels{1}), ylabel(ha,labels{2})
ax = axis(ha);
hc(1) = line([0 0],[ax(3) ax(4)],'Parent',ha,'Color','white','hittest','off');
hc(2) = line([ax(1) ax(2)],[0 0],'Parent',ha,'Color','white','hittest','off');
ptext = ax([1 3]) - [0 0.03].*(ax([2 4])-ax([1 3]));
ht = text('Parent',ha,'Position',ptext,'String','text');

info.image = hi;
info.cross = hc;
info.text = ht;
info.ijk = [0 0 1];
info.frame = 0;
setappdata(ha,'oldaxis',axis(ha))
if info.active, set(ha,'ButtonDownFcn',{@CallBack,ha,'mouse2d'}), end
setappdata(ha,'fn_4Dview',info)

%---------------------------------------------------------------------
function InitQuiverAxes(ha)
% TODO: Update!!! use Init2DAxes as a model

axes(ha)
set(get(ha,'Parent'),'DoubleBuffer','on')

info = getappdata(ha,'fn_4Dview');
s = info.sizes;
data = info.data;

if size(data,3)==3
    hi = imagesc(zeros(s(1),s(2))','hittest','off',info.clip{:});
    hold on
elseif size(data,3)==2
    hi = 0;
else
    error programming
end

hq = quiver(zeros(s(1),s(2)),zeros(s(1),s(2)),info.options{:});
if hi, hold off, end

ax = axis(ha);
hc(1) = line([0 0],[ax(3) ax(4)],'Color','white','hittest','off');
hc(2) = line([ax(1) ax(2)],[0 0],'Color','white','hittest','off');

info.image = hi;
info.quiver = hq;
info.cross = hc;
info.ijk = [0 0 1];
info.frame = 0;
setappdata(ha,'oldaxis',axis(ha))
if info.active, set(ha,'ButtonDownFcn',{@CallBack,ha,'mouse2d'}), end
setappdata(ha,'fn_4Dview',info)
set(ha,'NextPlot','Add')

%---------------------------------------------------------------------
function Init3DFigure(hf)

figure(hf), clf
set(hf,'DoubleBuffer','on','KeyPressFcn','')

info = getappdata(hf,'fn_4Dview');
s = info.sizes;
s = s(info.xyzperm);
scale = info.scale(info.xyzperm);
ticks = {(0:s(1)-1)*scale(1),(0:s(2)-1)*scale(2),(0:s(3)-1)*scale(3)};
labels = info.labels(info.xyzperm);

% Here, axes and control buttons are just created; they are later set to
% correct positions and sizes by invoking Resize3DFigure
ax1 = axes('Parent',hf);
ax2 = axes('Parent',hf);
ax3 = axes('Parent',hf);
ax4 = axes('Parent',hf);
set(ax4,'visible','off')
ha = [ax1 ax2 ax3];


center = zeros(1,2);
if info.active
    % + control [position d�finie par un vecteur de taille 6 : position
    % du centre (en % de la taille de la fenetre), puis position / au centre
    % (en pixels), puis largeur et hauteur (en pixels)]
    hu(1) = uicontrol('parent',hf,'CallBack',{@MoveStep,hf,'controlbackward'},'String','|');
    setappdata(hu(1),'position',[center -10 30 20 20]);
    hu(2) = uicontrol('parent',hf,'CallBack',{@MoveStep,hf,'controlforward'},'String','|');
    setappdata(hu(2),'position',[center -10 -10 20 20]);
    hu(3) = uicontrol('parent',hf,'CallBack',{@MoveStep,hf,'controlleft'},'String','-');
    setappdata(hu(3),'position',[center -30 10 20 20]);
    hu(4) = uicontrol('parent',hf,'CallBack',{@MoveStep,hf,'controlright'},'String','-');
    setappdata(hu(4),'position',[center 10 10 20 20]);
    hu(5) = uicontrol('parent',hf,'CallBack',{@MoveStep,hf,'controldown'},'String','\');
    setappdata(hu(5),'position',[center 10 -10 20 20]);
    hu(6) = uicontrol('parent',hf,'CallBack',{@MoveStep,hf,'controlup'},'String','\');
    setappdata(hu(6),'position',[center -30 30 20 20]);
end

hi(1) = imagesc(ticks{1},ticks{2},zeros(s(2),s(1)),'parent',ax1,'hittest','off',info.clip{:}); 
hi(2) = imagesc(ticks{3},ticks{2},zeros(s(2),s(3)),'parent',ax2,'hittest','off',info.clip{:});
hi(3) = imagesc(ticks{1},ticks{3},zeros(s(3),s(1)),'parent',ax3,'hittest','off',info.clip{:});
set(ax1,'xdir','normal','ydir','normal')
set(ax2,'xdir','normal','ydir','normal')
set(ax3,'xdir','normal','ydir','reverse')
xlabel(ax1,labels{1}), ylabel(ax1,labels{2})
xlabel(ax2,labels{3}), ylabel(ax2,labels{2})
xlabel(ax3,labels{1}), ylabel(ax3,labels{3})

axis1 = axis(ha(1)); 
axis2 = axis(ha(2));
ax = [axis1 axis2(1:2)]; clear axis1 axis2
info.oldaxis = ax;
info.curaxis = ax;

x = 0; y = 0; z = 0;
hc(1) = line([x x],[ax(3) ax(4)],'Parent',ha(1),'Color','white','hittest','off');
hc(2) = line([ax(1) ax(2)],[y y],'Parent',ha(1),'Color','white','hittest','off');
hc(3) = line([z z],[ax(3) ax(4)],'Parent',ha(2),'Color','white','hittest','off');
hc(4) = line([ax(5) ax(6)],[y y],'Parent',ha(2),'Color','white','hittest','off');
hc(5) = line([x x],[ax(5) ax(6)],'Parent',ha(3),'Color','white','hittest','off');
hc(6) = line([ax(1) ax(2)],[z z],'Parent',ha(3),'Color','white','hittest','off');

ht(1) = uicontrol('parent',hf,'HorizontalAlignment','center','style','text');
setappdata(ht(1),'position',[center -80 -30 160 20]);
ht(2) = uicontrol('parent',hf,'HorizontalAlignment','center','style','text');
setappdata(ht(2),'position',[center -80 -50 160 20]);

info.axes = [ax1 ax2 ax3 ax4];
info.controls = hu;
info.images = hi;
info.cross = hc;
info.text = ht;
info.ijk = [0 0 0];
info.frame = 0;
setappdata(hf,'fn_4Dview',info)
set(hf,'ResizeFcn',{@Resize3DFigure})
% set axes and button to correct positions and sizes
Resize3DFigure(hf)
setappdata(ax1,'oldaxis',axis(ax1))
setappdata(ax2,'oldaxis',axis(ax2))
setappdata(ax3,'oldaxis',axis(ax3))
if info.active
    set(ax1,'ButtonDownFcn',{@CallBack,hf,'mouse3d1'})
    set(ax2,'ButtonDownFcn',{@CallBack,hf,'mouse3d2'})
    set(ax3,'ButtonDownFcn',{@CallBack,hf,'mouse3d3'})
end

%---------------------------------------------------------------------
function Resize3DFigure(varargin)

hf = varargin{1};
info = getappdata(hf,'fn_4Dview');

ax = info.curaxis;
zfact = info.zfact;
sm = [ax(2)-ax(1) ax(4)-ax(3) (ax(6)-ax(5))*zfact];
sa = sm(1)+sm(3); sb = sm(3)+sm(2);

fpos = get(hf,'position');
if fpos(3)/sa > fpos(4)/sb
    yscale = 0.8/sb;
    xscale = yscale*fpos(4)/fpos(3);
else
    xscale = 0.8/sa;
    yscale = xscale*fpos(3)/fpos(4);
end
xblnk = (.9-xscale*sa)/2;
yblnk = (.9-yscale*sb)/2;

set(info.axes(1),'Position',[xblnk yblnk+.1+yscale*sm(3) xscale*sm(1) yscale*sm(2)]);
set(info.axes(2),'Position',[xblnk+.1+xscale*sm(1) yblnk+.1+yscale*sm(3) xscale*sm(3) yscale*sm(2)]);
set(info.axes(3),'Position',[xblnk yblnk xscale*sm(1) yscale*sm(3)]);
set(info.axes(4),'Position',[xblnk+.1+xscale*sm(1) yblnk xscale*sm(3) yscale*sm(3)]);

center = [xblnk+.1+xscale*sm(1)+xscale/2*sm(3) yblnk+yscale/2*sm(3)];
UpdateControlPositions(hf,[],center)

%---------------------------------------------------------------------
function UpdateControlPositions(hf,dum,center)

s = get(hf,'Position'); 
s = s([3 4]);
hlist = findobj(hf,'type','uicontrol');
for hu = hlist(:)'
    position = getappdata(hu,'position');
    if isempty(position), continue, end
    if nargin<3
        center = position([1 2]);
    end
    if isempty(position), continue, end
    set(hu,'position',[s(1)*center(1)+position(3) s(2)*center(2)+position(4) position(5:6)])
end

%---------------------------------------------------------------------
function DeleteControl(dum1,dum2,hu)

if nargin<3, hu=dum1; end
try delete(hu), catch end

%---------------------------------------------------------------------
function InitMeshFigure(hf)

clf(hf)
set(hf,'DoubleBuffer','on','KeyPressFcn','')

ha = axes('parent',hf);
info = getappdata(hf,'fn_4Dview');
mesh = info.mesh;
[vertex faces] = deal(mesh{:});
nvertex = size(vertex,2);
vcolor=ones(nvertex,1);

% TODO: use something faster?
ho=patch('Vertices',vertex','Faces',faces','FaceVertexCdata',vcolor,...
    'LineStyle','-',...
    'CDataMapping','scaled','FaceColor','flat',...
    'AmbientStrength', 0.6, 'FaceLighting', 'flat',...
    'HitTest','off');

cameratoolbar
camorbit(0,-90)
axis equal
% camorbit(-135,0)
% camlight
% camorbit(180,0)
% camlight

x = vertex(1,1); y = vertex(2,1); z = vertex(3,1);  
hc(1) = line(x,y,z,'Marker','*','Color','white','LineWidth',3,'HitTest','off');
hc(2) = line(x,y,z,'Marker','o','Color','red','LineWidth',3,'MarkerSize',12,'HitTest','off');

ht = uicontrol('style','text','position',[5 5 220 15],'string','text','HorizontalAlignment','left');

info.object = ho;
info.cross = hc;
info.text = ht;
info.ind = 1;
info.frame = 0;
set(ha,'ButtonDownFcn',{@CallBack,hf,'mousemesh'})
setappdata(hf,'fn_4Dview',info)

%---------------------------------------------------------------------
function InitPlotAxes(ha)

info = getappdata(ha,'fn_4Dview');
info.curaxis = [];
info.curaxisindices = [];
info.ind = 0;

info.hplot = [];
info.hline = [];
info.htsel = [];

% Callbacks
set(ha,'ButtonDownFcn',{@CallBack,ha,'mouseplot'},'NextPlot','ReplaceChildren')
hf = get(ha,'parent');
pos = get(ha,'position');
hu(1) = uicontrol('parent',hf,'CallBack',{@MoveStep,ha,'timeleft'},'String','<');
setappdata(hu(1),'position',[pos(1) pos(2) -20 -20 20 20]);
hu(2) = uicontrol('parent',hf,'CallBack',{@MoveStep,ha,'timeright'},'String','>');
setappdata(hu(2),'position',[pos(1)+pos(3) pos(2) 0 -20 20 20]);
hu(3) = uicontrol('parent',hf,'CallBack',{@MoveStep,ha,'windowleft'},'String','<<');
setappdata(hu(3),'position',[pos(1) pos(2) -40 -20 20 20]);
hu(4) = uicontrol('parent',hf,'CallBack',{@MoveStep,ha,'windowright'},'String','>>');
setappdata(hu(4),'position',[pos(1)+pos(3) pos(2) 20 -20 20 20]);
%set(hf,'KeyPressFcn',{@MoveStep,ha,'keyboard'}, ...
%    'ResizeFcn',{@UpdateControlPositions},'DoubleBuffer','on')
set(hf,'ResizeFcn',{@UpdateControlPositions},'DoubleBuffer','on')
set(ha,'DeleteFcn',{@DeleteControl,hu})
UpdateControlPositions(hf)

setappdata(ha,'fn_4Dview',info);

%---------------------------------------------------------------------
function InitTimeSlider(handle)
% handle can be figure or uicontrol

info = getappdata(handle(1),'fn_4Dview');
switch get(handle(1),'type')
    case 'figure'
        hf = handle;
        set(hf,'position',[800 500 300 45],'menubar','none', ...
            'name','Time control','visible','on')
        info.slider = uicontrol('style','slider','position',[5 5 290 20]);
        info.text = uicontrol('style','text','position',[100 30 100 10],'String','text');
        info.roundbutton = uicontrol('position',[230 27 20 15],'String','r', ...
            'CallBack',{@SliderCallback,handle});
    case 'uicontrol'
        info.slider = handle(1);
        if length(handle)>1
            info.text = handle(2);
        else
            info.text = uicontrol('style','text','visible','off');
        end
end

m = info.t0; n = info.nt; M = m + info.dt*(n-1);
set(info.slider,'Min',m,'Max',M,'SliderStep',[1/(n-1) 1/15],'Value',(m+M)/2, ...
    'CallBack',{@SliderCallback,handle(1)});

setappdata(handle(1),'fn_4Dview',info);

%---------------------------------------------------------------------
function Unregister(varargin)
% function Unregister([updatefcns][,keys])

% Input
updatefcns = [];
keys = [];
for i=1:nargin
    arg = varargin{i};
    switch class(arg)
        case {'char','function_handle'}
            updatefcns = {arg};
        case 'cell'
            updatefcns = arg;
        case 'double'
            keys = arg;
        otherwise
            error('wrong argument type for unregister action')
    end
end

% search and delete appropriate objects
hlist0 = findobj('type','figure','Tag','fn_4Dview');
for hobj = hlist0(:)'
    info = getappdata(hobj,'fn_4Dview');
    if ~strcmp(info.type,'ext'), continue, end
    if ~isempty(updatefcns) && ~ismember(info.options{1},updatefcns), continue, end
    if ~isempty(keys) && ~ismember(info.key,keys), continue, end
    delete(hobj);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DISPLAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Update(hobj)

info = getappdata(hobj,'fn_4Dview');

% Update internal information of the object
changes = info.haschanged;
if changes.xyz
    switch info.type
        case {'mesh' 'meshplot'}
            info.ind = XYZ2Ind(info,info.xyzt(1:3)');
        otherwise
            [info.ind info.ijk info.ijk2] = XYZ2Ind(info,info.xyzt(1:3)');
    end
end
if changes.t
    info.frame = T2Frame(info,info.xyzt(4));
end
if changes.xyzselection && ~strcmp(info.type,'mesh') 
    % mesh don't use real world coordinates for selections
    % - at least for the moment
    info.indselection = XYZsel2Indsel(info,info.xyzselection);
end
if changes.tselection
    info.frameselection = Tsel2Framesel(info,info.tselection);
end
setappdata(hobj,'fn_4Dview',info);

% Update display    
switch info.type
    case 'timeslider'
        UpdateTimeSlider(hobj)
    case {'2dplot','3dplot','meshplot'}
        UpdatePlot(hobj)
    case '2d'
        Update2D(hobj)
    case '3d'
        try
            Update3D(hobj)
        catch % figure a �t� abim�e ? on tente de la reconstruire
            Init3DFigure(hobj)
            Update3D(hobj)
        end
    case 'quiver'
        UpdateQuiver(hobj)
    case 'mesh'
        try
            UpdateMesh(hobj)
        catch % figure a �t� abim�e ? on tente de la reconstruire
            InitMeshFigure(hobj)
            UpdateMesh(hobj)
        end
    case 'ext'
        UpdateExt(hobj)
end

% Reinit 'haschanged'
info = getappdata(hobj,'fn_4Dview');
info.haschanged = struct('xyz',false,'t',false,'xyzselection',false, ...
    'tselection',false,'plotaxis',false);
setappdata(hobj,'fn_4Dview',info);

%---------------------------------------------------------------------
function Update2D(hobj)

info = getappdata(hobj,'fn_4Dview');
changes = info.haschanged;

% Redraw image
if changes.t || changes.tselection || changes.xyzselection
    % compute image (if necessary, average frames)
    if isempty(info.frameselection)
        frames = info.frame;
    else
        frames = info.frameselection;
    end
    im = info.data(:,frames,info.channel);
    im = mean(im,2);
    im = reshape(im,info.sizes(1:2));
    setappdata(hobj,'currentdisplay',im);	% make the image available in base workspace
    
    % clip
    if isempty(info.clip)
        clip = [min(im(:)) max(im(:))];
        if diff(clip)==0, clip = clip+[-1 1]; end
        set(info.hobj,'clim',clip)
    else
        clip = get(info.hobj,'clim');
    end

    % if sets of points are selected, highlight them with color
    if ~isempty(info.indselection)
        im = HighlightSelection(im(:),info.indselection,clip);
        im = reshape(im,[info.sizes(1:2) 3]);
    end
    
    % display - take into consideration xyzperm
    set(info.image,'CData',permute(im,[info.xyzperm([2 1]) 3]))
end
 
% Redraw cross
if changes.xyz
    xyperm = info.xyzperm(1:2);
    ijperm = info.ijk2(xyperm);
    scale = info.scale(xyperm);
    pt = (ijperm-1).*scale;
    set(info.cross(1),'XData',pt([1 1]))
    set(info.cross(2),'YData',pt([2 2]))
end

% Redraw value
im = get(info.image,'CData');
set(info.text,'String', ...
    ['val(' num2str(info.ijk(1)) ',' num2str(info.ijk(2)) ')=' ...
    num2str(im(info.ijk(2),info.ijk(1)))])

%---------------------------------------------------------------------
function UpdateQuiver(hobj)
% TODO: Update!!!

disp('Quiver mode is disabled in this moment')

return

sf = gcf;

info = getappdata(hobj,'fn_4Dview');
info.xyzt = xyzt;
oldframe = info.frame;
if isempty(info.frameselection)
    info.frame = XYZT2Frame(hobj,xyzt);
else
    info.frame = -1;
end
[ind ijk] = XYZT2Ind(hobj,xyzt);
info.ijk = ijk(:)';
setappdata(hobj,'fn_4Dview',info)

if info.frame~=oldframe
    if isempty(info.frameselection)
        frames = info.frame;
    else
        frames = Tsel2Frame(hobj,info.frameselection);
    end
    if info.image
        im = reshape(info.data(:,info.frame,3),info.sizes(1:2));
        set(info.image,'CData',im')
    end
    
    delete(info.quiver)
    a = reshape(mean(info.data(:,frames,1),2),info.sizes(1:2));
    b = reshape(mean(info.data(:,frames,2),2),info.sizes(1:2));
    axes(hobj)
    info.quiver = quiver(a,b,info.options{:});
    set(info.quiver,'hittest','off')
    setappdata(hobj,'fn_4Dview',info)
end

set(info.cross(1),'XData',ijk([1 1]))
set(info.cross(2),'YData',ijk([2 2]))

figure(sf)

%---------------------------------------------------------------------
function Update3D(hobj)

info = getappdata(hobj,'fn_4Dview');

% Frames
if isempty(info.frameselection)
    frames = info.frame;
else
    frames = info.frameselection;
end
channel = info.channel;

% Redraw sections
data = reshape(info.data,info.sizes);
xyzperm = info.xyzperm;
% which dimensions are displayed in the three axes
dimdisp = {xyzperm([1 2]),xyzperm([3 2]),xyzperm([1 3])};
% loop on three axes
for k=1:3
   subind = mat2cell(info.ijk,[1 1 1],1);       % ex: subind = {23,15,4}
   [subind{dimdisp{k}}] = deal(':');            % ex: subind = {':',15,':'}
   subdata = data(subind{:},frames,channel);    % ex: subddata  = data(:,15,:,frame,channel)
   subdata = mean(subdata,4);                   % frame averaging
   im = squeeze(subdata);
   if diff(dimdisp{k})>0, im=im'; end
   % display
   set(info.images(k),'CData',im)
end

% Redraw cross
ijkperm = info.ijk2(xyzperm);
scale = info.scale(xyzperm);
pt = (ijkperm-1).*scale;
set(info.cross(1),'XData',pt([1 1]))
set(info.cross(2),'YData',pt([2 2]))
set(info.cross(3),'XData',pt([3 3]))
set(info.cross(4),'YData',pt([2 2]))
set(info.cross(5),'XData',pt([1 1]))
set(info.cross(6),'YData',pt([3 3]))

% Redraw value
set(info.text(1),'String', ...
    ['val(' num2str(info.ijk(1)) ',' num2str(info.ijk(2)) ',' num2str(info.ijk(3)) ')=' ...
        num2str(data(info.ijk(1),info.ijk(2),info.ijk(3),info.frame,channel))])
set(info.text(2),'String', ...
    ['xyzt = ' num2str(info.xyzt(1:3),'%.1f ')])

%---------------------------------------------------------------------
function UpdateMesh(hf)

info = getappdata(hf,'fn_4Dview');
changes = info.haschanged;

% Repaint mesh
if changes.t || changes.tselection
    if isempty(info.frameselection)
        frames = info.frame;
    else
        frames = Tsel2Frame(hf,info.frameselection);
    end
    vcolor = mean(info.data(:,frames,info.channel),2);
    vcolor = HighlightSelection(vcolor,info.indselection,info.clip);
    if ~isempty(info.heeginv), vcolor = info.heeginv * vcolor; end
    faces = info.mesh{2}; 
    nf = size(faces,2); nc = size(vcolor,2);
    fcolor = vcolor(faces,:);
    fcolor = shiftdim(mean(reshape(fcolor,[3 nf nc])),1);
    set(info.object,'FaceVertexCdata',fcolor)
end

% Selected point marker and value
if isempty(info.indselection)
    vertex = info.mesh{1};
    if changes.xyz || info.ind==0
        ind = info.ind;
        x = vertex(1,ind); y = vertex(2,ind); z = vertex(3,ind);
        set(info.cross,'XData',x,'YData',y,'ZData',z)
    else
        x = vertex(1,info.ind); y = vertex(2,info.ind); z = vertex(3,info.ind);
    end

    % TODO : speed efficient ?
    vcolor = get(info.object,'FaceVertexCdata'); val = vcolor(info.ind);
    set(info.text,'string',['val(' num2str(x,'%.1f') ',' num2str(y,'%.1f') ',' num2str(z,'%.1f') ...
        ') = ' num2str(val)])
else
    set(info.text,'string','')
end

setappdata(hf,'fn_4Dview',info)

    
%---------------------------------------------------------------------
function UpdatePlot(ha)

info = getappdata(ha,'fn_4Dview');
t = info.xyzt(4);
changes = info.haschanged;

% consider only instants which fall inside the current axis display
if changes.plotaxis
    if isempty(info.curaxis)
        f = 1:info.nt;
    else
        tidx = info.t0 + (0:info.nt-1)*info.dt;
        f = find(tidx>info.curaxis(1));
        if isempty(f), f=length(tidx); elseif f(1)>1; f=[f(1)-1 f(:)']; end
        f = f(tidx(f)<info.curaxis(2));
        if isempty(f), f=1; elseif f(end)<length(tidx); f=[f f(end)+1]; end
    end
    info.curaxisindices = f;
end

% change displayed data
if changes.xyz || changes.xyzselection || changes.plotaxis
    % x axis
    tidxtoplot = info.t0 + (info.curaxisindices-1)*info.dt;
    
    % y axis
    % space selections?
    nsel = length(info.indselection);
    selempty = true;
    for i=1:nsel
        if ~isempty(info.indselection{i})
            selempty = false;
            break
        end
    end
    if selempty
        indselection = {info.ind};
        nsel = 1;
    else
        indselection = info.indselection;
    end
    ncurves = nsel*info.nchan;
    colors = colorset; ncolors = size(colors,1);
    datatoplot = zeros(length(info.curaxisindices),ncurves);
    try
        delete(info.hplot)
    catch
        disp('could not delete previous plot, suppose an error occured')
    end
    %info.hplot = zeros(1,ncurves);
    info.hplot = [];
    for i=1:nsel
        indsel = indselection{i};
        if isempty(indsel), continue, end
        if isempty(info.heeginv)
            subdata = info.data(indsel,info.curaxisindices,:);
        else
            % TODO: verifier ca
            subdata = (info.heeginv(indsel,:)*info.data(:,info.curaxisindices,1))';
        end
        subdata = mean(subdata,1); % average over selected indices
        subdata = shiftdim(subdata,1); % subdata is now time x component
        datatoplot(:,1+(i-1)*info.nchan:i*info.nchan) = subdata;
        % display
        for j=1:info.nchan
            if nsel==1, kcol = j; else kcol = i; end
            col = colors(mod(kcol-1,ncolors)+1,:);
            %info.hplot((i-1)*info.nchan+j) = ...
            info.hplot(end+1) = ...
                line('parent',ha,'xdata',tidxtoplot,'ydata',subdata(:,j), ...
                'HitTest','off','color',col);
        end
    end
    % make the data available in base workspace
    setappdata(ha,'currentdisplay',datatoplot);
    
    % change axis view
    % x axis
    if ~isempty(info.curaxis)
        axx = info.curaxis(1:2);
    else
        axx = info.t0 + [0 (info.nt-1)*info.dt];
    end
    % TODO: fix the axis bug otherwise?
    if diff(axx)==0, axx = axx(1) + [-.5 .5]; end
    % y axis
    axy = [min(datatoplot(:)) max(datatoplot(:))];
    if diff(axy)==0, axy=[axy(1)-1 axy(2)+1]; end
    % change axis view
    axis(ha,[axx axy])    
end

% Redraw vertical line to mark selected time
if changes.xyz || changes.xyzselection || changes.plotaxis || changes.t
    ax = axis(ha);
    delete(info.hline)
    info.hline = line([t t],ax([3 4]),'color','black','parent',ha,'HitTest','off');
end

% Show the time selection for averaging images
if changes.tselection || changes.xyz || changes.xyzselection || changes.plotaxis
    ax = axis(ha);
    ntsel = length(info.tselection);
    delete(info.htsel)
    info.htsel = zeros(1,ntsel);
    for k=1:ntsel
        tsel = info.tselection{k};
        switch length(tsel)
            case 1
                info.htsel(k) = line(tsel,ax(3),'marker','.', ...
                    'color','r','parent',ha,'HitTest','off');
            case 2
                info.htsel(k) = line(tsel,[ax(3) ax(3)],'linestyle','-','linewidth',5, ...
                    'color','r','parent',ha,'HitTest','off');
        end
    end
end

setappdata(ha,'fn_4Dview',info) 

%---------------------------------------------------------------------
function UpdateTimeSlider(handle)

info = getappdata(handle,'fn_4Dview');

val = info.xyzt(4);
val = min(get(info.slider,'Max'),max(get(info.slider,'Min'),val));
set(info.text,'String',num2str(floor(val*100)/100))
set(info.slider,'Value',val);

%---------------------------------------------------------------------
function UpdateExt(hobj)

info = getappdata(hobj,'fn_4Dview');

if isstr(info.options)
    assignin('base','info',info)
    evalin('base',info.options)
elseif(ishandle(info.options{1}))
    assignin('base',info.options{2},info)
    evalin('base',info.options{1})
else
    feval(info.options{1},info,info.options{2:end})
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CallBack(ha,dum2,hobj,action)
% different selection types are:
% - point with left button          -> change cursor
% - area with left button           -> zoom to region
% - double-click with left button   -> zoom reset
%   (or point with middle button outside of axis)
% - point/area with middle button   -> add point/area to current selection
% - double-click with middle button -> cancel current selection
%   (or point with middle button outside of axis)
% - point/area with right button    -> add new selection
% - double-click with right button  -> cancel all selections
%   (or point with right button outside of axis)

oldselectiontype = getappdata(hobj,'oldselectiontype');
info = getappdata(hobj,'fn_4Dview');
selectiontype = get(info.hf,'selectiontype');
setappdata(hobj,'oldselectiontype',selectiontype)

point =  get(ha,'CurrentPoint');

% click outside of axis
ax = axis(ha);
if (point(1,1)<ax(1) || point(1,1)>ax(2) || point(1,2)<ax(3) || point(1,2)>ax(4))
    oldselectiontype = selectiontype;
    selectiontype = 'outside';
end

switch selectiontype
    case 'normal'                                   % CHANGE VIEW AND/OR MOVE CURSOR
        switch action
            case {'mouse2d','mouse3d1','mouse3d2','mouse3d3','mouseplot'}
                rect = fn_mouse(ha,'rect-');
                if all(rect(3:4))                   % zoom in
                    switch action
                        case 'mouseplot'
                            ChangeAxis(hobj,'mouseplot',[rect(1)+[0 rect(3)] rect(2)+[0 rect(4)]])
                        case 'mouse2d'
                            ChangeAxis(hobj,'mouse2d', ...
                                [rect(1)+[0 rect(3)] rect(2)+[0 rect(4)]],getappdata(ha,'oldaxis'))
                        case {'mouse3d1','mouse3d2','mouse3d3'}
                            newax = info.curaxis;
                            ax = [rect(1)+[0 rect(3)] rect(2)+[0 rect(4)]];
                            switch action
                                case 'mouse3d1'
                                    newax([1 2 3 4]) = ax;
                                case 'mouse3d2'
                                    newax([5 6 3 4]) = ax;
                                case 'mouse3d3'
                                    newax([1 2 5 6]) = ax;
                            end
                            ChangeAxis(hobj,'mouse3d',newax,info.oldaxis)
                    end
                else    
                    if strcmp(action,'mouseplot')   % move t
                        t = point(1,1);
                        ChangeT(info.key,t);
                    else                            % move cross
                        % since ticks are scaled, it is necessary to
                        % bring back point coordinates to indices coordinates
                        xyzperm = info.xyzperm;
%                         ijk = info.ijk(:);
%                         scale = info.scale(xyzperm);                      
%                         switch action
%                             case 'mouse2d'
%                                 pt = [point(1,1)/scale(1)+1 point(1,2)/scale(2)+1];
%                                 ijk(xyzperm([1 2])) = pt;
%                                                     % in addition, change selection order!
%                                 ChangeXYZsel(info,XYZ2Ind(info,point),'changefocus')
%                             case 'mouse3d1'
%                                 pt = [point(1,1)/scale(1)+1 point(1,2)/scale(2)+1];
%                                 ijk(xyzperm([1 2])) = pt;
%                             case 'mouse3d2'
%                                 pt = [point(1,1)/scale(3)+1 point(1,2)/scale(2)+1];
%                                 ijk(xyzperm([3 2])) = pt;
%                             case 'mouse3d3'
%                                pt = [point(1,1)/scale(1)+1 point(1,2)/scale(3)+1];
%                                ijk(xyzperm([1 3])) = pt;
%                         end
%                         xyz = IJK2XYZ(info,ijk);
                        xyz = info.xyzt(1:3); xyz = xyz(:);
                        switch action
                            case 'mouse2d'
                                xyz(xyzperm([1 2])) = point(1,1:2);
                                                    % in addition, change selection order!
                                ChangeXYZsel(info,XYZ2Ind(info,xyz),'changefocus')
                            case 'mouse3d1'
                                xyz(xyzperm([1 2])) = point(1,1:2);
                            case 'mouse3d2'
                                xyz(xyzperm([3 2])) = point(1,1:2);
                            case 'mouse3d3'
                                xyz(xyzperm([1 3])) = point(1,1:2);
                        end
                        ChangeXYZ(info.key,xyz)
                    end
                end
            case 'mousemesh'                         % move cursor
                [ind ijk] = fn_meshselectpoint(info.mesh,point);
                xyz = IJK2XYZ(info,ijk);
                ChangeXYZ(info.key,xyz)
        end
    case {'extend','alt'}                           % POINTS SELECTION
        switch selectiontype
            case 'extend'
                selflag = 'add';
            case 'alt'
                selflag = 'new';
        end
        switch action
            case 'mouse2d'
                if strcmp(info.type,'quiver')
                    disp('Points selection not implemented for quiver yet')
                    return 
                end
                poly = fn_mouse('poly-')';
                xyperm = info.xyzperm(1:2);
                scale = info.scale(xyperm);
                % convert poly from display system to indices system
                poly = [poly(:,xyperm(1))/scale(1)+1 poly(:,xyperm(2))/scale(2)+1];
                % convert poly from indices system to real world system
                xyzsel = IJK2XYZ(info,poly');
                ChangeXYZsel(info,xyzsel,selflag)                        
            case 'mousemesh'
                indsel = fn_meshselectpoint(info.mesh,point);
                ChangeMeshIndsel(info,indsel,selflag)                        
            case {'mouse3d1','mouse3d2','mouse3d3'}
                disp('Points selection not implemented for 3D images yet')
                return
            case 'mouseplot'
                rect = fn_mouse('rect-');
                if rect(3)==0                       % select a time point
                    tsel = rect(1);
                else                                % select a temporal segment
                    tsel = [rect(1) rect(1)+rect(3)];
                end
                ChangeTsel(info,tsel,selflag)                        
           otherwise
                return
        end
    case 'open'
        switch oldselectiontype
            case 'normal'                           % zoom out
                switch action
                    case 'mouseplot'
                        ChangeAxis(hobj,'mouseplot',[])
                    case 'mouse2d'
                        ChangeAxis(hobj,action, ...
                            getappdata(ha,'oldaxis'),getappdata(ha,'oldaxis'))
                    case {'mouse3d1','mouse3d2','mouse3d3'}
                        ChangeAxis(hobj,'mouse3d',info.oldaxis,info.oldaxis)
                end
        end
    case 'outside'
        switch oldselectiontype
            case {'extend','alt'}                 	% unselect points
                switch oldselectiontype
                    case 'extend'
                        resetflag = 'resetone';   	% unselect current set of points/instants
                    case 'alt'
                        resetflag = 'resetall';     % unselect all points/instants
                end
                switch action
                    case 'mouse2d'
                        ChangeXYZsel(info,[],resetflag)
                    case 'mousemesh'
                        ChangeMeshIndSel(info,[],resetflag)
                    case 'mouseplot'
                        ChangeTsel(info,[],'reset')
                end
        end
end


%---------------------------------------------------------------------
function MoveStep(dum1,dum2,hobj,action)
% appele par les controles dans la vue sections (3D)
% ou dans un plot

info = getappdata(hobj,'fn_4Dview');
s = info.sizes; xyzt = info.xyzt(:);
if strcmp(action,'keyboard')  
    keypressed = double(get(info.hf,'CurrentCharacter'));
    if isempty(keypressed), return, end
    switch keypressed
        case 28
            frame = max(info.frame-1,1);
        case 29
            frame = min(info.frame+1,info.nt);
        otherwise
            return
    end
    t = info.t0 + inf.dt*(frame-1);
    ChangeT(info.key,t);
elseif findstr(action,'control')
    ijk = info.ijk(:); 
    xyzperm = info.xyzperm;
    switch action
        case 'controlup'
            ijk(xyzperm(3)) = max(1,ijk(xyzperm(3))-1);
        case 'controldown'
            ijk(xyzperm(3)) = min(s(3),ijk(xyzperm(3))+1);
        case 'controlleft'
            ijk(xyzperm(1)) = max(1,ijk(xyzperm(1))-1);
        case 'controlright'
            ijk(xyzperm(1)) = min(s(1),ijk(xyzperm(1))+1);
        case 'controlforward'
            ijk(xyzperm(2)) = max(1,ijk(xyzperm(2))-1); 
        case 'controlbackward'
            ijk(xyzperm(2)) = min(s(2),ijk(xyzperm(2))+1);
    end 
    xyz = IJK2XYZ(info,ijk);
    ChangeXYZ(info.key,xyz);
elseif findstr(action,'window')
    curaxis = info.curaxis;
    if isempty(curaxis), return, end   
    taille = curaxis(2)-curaxis(1);
    switch action
        case 'windowleft'
            step = -taille;
        case 'windowright'
            step = taille;
    end
    ax = axis(hobj);
    ChangeAxis(hobj,'windowplot',[curaxis+step ax(3:4)])
    ChangeT(info.key,xyzt(4)+step)
elseif findstr(action,'time')
    switch action
        case 'timeleft'
            frame = max(info.frame-1,1);
        case 'timeright'
            frame = min(info.frame+1,info.nt);
    end
    t = info.t0 + info.dt*(frame-1);
    ChangeT(info.key,t);
else
    error programming
end

%---------------------------------------------------------------------
function SliderCallback(hu,dum2,handle)
% called by 'time slider'

info = getappdata(handle,'fn_4Dview');
switch get(hu,'style')
    case 'slider'
        t = get(hu,'Value');
        ChangeT(info.key,t);
    case 'pushbutton'
        t = get(info.slider,'Value');
        frame = T2Frame(handle,t);
        ChangeT(info.key,info.t0 + info.dt*(frame-1));
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LINKS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hlist = Linked(key)
% returns objects which have the same key

hlist0 = findobj('Tag','fn_4Dview');
hlist = [];
for hobj = hlist0'
    info = getappdata(hobj,'fn_4Dview');
    if info.key == key
        hlist(end+1) = hobj;
    end
end

%---------------------------------------------------------------------
function ChangeAxis(hobj0,action,ax,oldaxis)
% action = 'mouse2d', 'mouse3d1', 'mouse3d2' ou 'mouse3d3'
% oldaxis est l'axe d'origine de l'endroit o� on a cliqu�
% 'key', 'action' et 'oldaxis' permettent d'identifier dans quelles fenetres on
% va r�aliser le changement de zoom avec 'ax'

info0 = getappdata(hobj0,'fn_4Dview');
hlist = Linked(info0.key);

% effectuer le changement de zoom dans toutes les fenetres liees de meme
% type
for hobj = hlist
    info = getappdata(hobj,'fn_4Dview');
    if strcmp(action,'mouse2d') && fn_ismemberstr(info.type,{'2d','quiver'})
        %if all(getappdata(hobj,'oldaxis')==oldaxis)
        axis(hobj,ax)
        if strcmp(info.type,'2d')
            ptext = ax([1 3]) - [0 0.03].*(ax([2 4])-ax([1 3]));
            set(info.text,'Position',ptext)
        end
        %end
    elseif strcmp(action,'mouse3d') && strcmp(info.type,'3d')
        axes = info.axes;
        axis(axes(1),ax([1 2 3 4]))
        axis(axes(2),ax([5 6 3 4]))
        axis(axes(3),ax([1 2 5 6]))
        info.curaxis = ax;
        setappdata(hobj,'fn_4Dview',info)
        Resize3DFigure(hobj)
    elseif fn_ismemberstr(action,{'mouseplot','windowplot'}) && fn_ismemberstr(info.type,{'2dplot','3dplot','meshplot'})
        emptyflag = isempty(ax);
        if emptyflag, info.curaxis = []; else info.curaxis = ax([1 2]); end
        info.haschanged.plotaxis = true;
        setappdata(hobj,'fn_4Dview',info)
        Update(hobj)
    end
end

if strcmp(action,'mouseplot') && ~isempty(ax)
    axis(hobj0,ax)
end

% %---------------------------------------------------------------------
% function ChangeAxisPlot(ha,ax)
% % l�g�rement diff�rent de ChangeAxis: pour les repr�sentations temporelles :
% % pas de liens entre les fenetres
% % soit curaxis vaut [] et alors on fait axis tight
% % soit curaxis est fix� et impose un nouvel intervalle temporel (abscisses)
% 
% % effectuer le changement de zoom dans les bonnes fenetres
% info = getappdata(ha,'fn_4Dview');
% 
% % effectuer le changement de zoom dans toutes les fenetres liees de meme
% % type
% info.haschanged.plotaxis = true; 
% setappdata(ha,'fn_4Dview',info)  
% Update(ha) 

%---------------------------------------------------------------------
function ChangeXYZ(key,xyz)

hlist = Linked(key);
for hobj = hlist
    info = getappdata(hobj,'fn_4Dview');
    info.xyzt(1:3) = xyz;
    info.haschanged.xyz = true;
    setappdata(hobj,'fn_4Dview',info)
    Update(hobj)
end

%---------------------------------------------------------------------
function ChangeT(key,t)

hlist = Linked(key);
for hobj = hlist
    info = getappdata(hobj,'fn_4Dview');
    info.xyzt(4) = t;
    info.haschanged.t = true;
    setappdata(hobj,'fn_4Dview',info)
    Update(hobj)
end

%---------------------------------------------------------------------
function ChangeXYZsel(info,xyzsel,flag)
% or ChangeXYZsel(info,ind,'changefocus')

% change spatial selections according to flag
xyzselection = info.xyzselection;
switch flag
    case 'add'
        if isempty(xyzselection), xyzselection={{}}; end
        xyzselection{end}{end+1} = xyzsel;
    case 'new'
        xyzselection{end+1} = {xyzsel};
    case 'resetone'
        xyzselection(end) = [];
    case 'resetall'
        xyzselection = {};
    case 'changefocus'
        ind = xyzsel;
        % find if there is an existing selection which contains ijk
        indselection = info.indselection;
        nsel = length(indselection);
        ksel = 0;
        for k=1:nsel
            if ismember(ind,indselection{k}), ksel=k; break, end
        end
        if ~ksel, return, end
        reorder = [setdiff(1:nsel,ksel) ksel];
        xyzselection = xyzselection(reorder);
end

% update linked objects
hlist = Linked(info.key);
for hobj = hlist
    info2 = getappdata(hobj,'fn_4Dview');
    % mesh don't go through real world coordinates for selections
    if strcmp(info2.type,'mesh'), continue, end
    info2.xyzselection = xyzselection;
    if strcmp(flag,'changefocus')
        % a bit dirty: we update indselection here, whereas it will be
        % updated in 'Update' in the other cases
        info2.indselection = info2.indselection(reorder);
    end
    info2.haschanged.xyzselection = true;
    setappdata(hobj,'fn_4Dview',info2)
    Update(hobj)
end

%---------------------------------------------------------------------
function ChangeMeshIndSel(info,indsel,flag)
% Special for mesh point selection:
% * don't go through real world coordinates but keep indices
% * link only to other meshes which are the same size

% add new selection to previous ones according to flag
indselection = info.indselection;
switch flag
    case 'add'
        if isempty(indselection), indselection={[]}; end
        indselection{end} = union(indselection{end},indsel);
    case 'new'
        indselection{end+1} = indsel;
    case 'resetone'
        indselection(end) = [];
    case 'resetall'
        indselection = {};
end

% update linked objects
hlist = Linked(info.key);
for hobj = hlist
    info2 = getappdata(hobj,'fn_4Dview');
    % link only to other meshes which are the same size
    if ~strcmp(info.type,'mesh') || ~isequal(size(info2.mesh{1}),size(info.mesh{1})) ...
            || ~isequal(size(info2.mesh{2}),size(info.mesh{2})), continue, end
    info2.indselection = indselection;
    info2.haschanged.indselection = true;
    setappdata(hobj,'fn_4Dview',info2)
    Update(hobj)
end

%---------------------------------------------------------------------
function ChangeTsel(info,tsel,flag)

% add new selection to previous ones according to flag
tselection = info.tselection;
switch flag
    case 'add'
        if isempty(tselection), tselection={[]}; end
        tselection{end+1} = tsel;
    case 'new'
        tselection = {tsel};
    case 'reset'
        tselection = {};
end

% update linked objects
hlist = Linked(info.key);
for hobj = hlist
    info2 = getappdata(hobj,'fn_4Dview');
    info2.tselection = tselection;
    info2.haschanged.tselection = true;
    setappdata(hobj,'fn_4Dview',info2)
    Update(hobj)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERSION XYZT <-> INDICES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ind, ijk, ijk2] = XYZ2Ind(info,xyz)
% ind  = global indices
% ijk  = i,j,k indices
% ijk2 = i,j,k indices but not rounded to next integer

% Input
switch size(xyz,1)
    case 2
        xyz(3:4,:) = 1;
    case 3
        xyz(4,:) = 1;
    otherwise
        error('xyz should have 2 or 3 rows')
end

% Convert to index
ijk2 = eye(3,4)*inv(info.mat)*xyz;
switch info.type
    case {'2d','2dplot','quiver','3d','3dplot','indices','timeslider'}
        s = info.sizes;  
        ijk = ijk2;
        for i=1:3
            ijk(i,:) = min(max(round(ijk(i,:)),1),s(i));
        end
        ind = ijk(1) + info.sizes(1) * ((ijk(2)-1) + info.sizes(2)*(ijk(3)-1));
        %if strcmp(info.type,'indices'), ind = info.ind(ind); end
    case 'ext'
        ijk = floor(ijk2);
        ind = 0;
    case {'mesh','meshplot'}
        ind = fn_meshclosestpoint(info.mesh{1},xyz(1:3));
    otherwise
        error programming 
end

%---------------------------------------------------------------------
function indselection = XYZsel2Indsel(info,xyzselection)

indselection = info.indselection;
if isempty(xyzselection)        % reset all
    indselection = {};
elseif isempty(indselection)    % old selections are unknown (new object) - need to rescan all of them
    nsel = length(xyzselection);
    indselection = cell(1,nsel);
    for i=1:nsel
        indselection{i} = [];
        for j=1:length(xyzselection{i})
            indsel = Poly2Inds(info,xyzselection{i}{j});
            indselection{i} = union(indselection{i},indsel);
        end
    end
else                            % need only to scan the last selection
    switch length(xyzselection) - length(indselection)
        case 1                  % new
            indselection{end+1} = [];
        case 0                  % add or reorder
        case -1                 % reset one
            indselection(end) = [];
        otherwise
            disp('problem, reinitializing selection')
            indselection = {};
    end
    indsel = Poly2Inds(info,xyzselection{end}{end});
    indselection{end} = union(indselection{end},indsel);
end

%---------------------------------------------------------------------
function indsel = Poly2Inds(info,poly)

% from real world to indices
[dum1 dum2 indpoly] = XYZ2Ind(info,poly);
switch info.type
    case {'2d','2dplot','quiver','quiverplot','ext','timeslider'}
        if any(info.sizes(1:2)==1)           % special case: one-dimentional data
            if info.sizes(1)==1, k=2; else k=1; end
            inds = indpoly(k,:);
            m = max(1,round(min(inds)));
            M = min(info.sizes(k),round(max(inds)));
            indsel = m:M;
        elseif size(indpoly,2)>1            % select points in a region
            mask = fn_poly2mask(indpoly,info.sizes);
            indsel = find(mask);
        else                                % select one point
            mask = zeros(info.sizes(1:2));
            point = round(indpoly(1:2))';
            if all(point>0) && all(point<=info.sizes(1:2))
                mask(point(1),point(2)) = 1;
            end
            indsel = find(mask);
        end
    otherwise
        error programming
end
        
%---------------------------------------------------------------------
function xyz = IJK2XYZ(info,ijk)

% Input
switch size(ijk,1)
    case 2
        ijk(3:4,:) = 1;
    case 3
        ijk(4,:) = 1;
    otherwise
        error('ijk should have 2 or 3 rows')
end

% Convert to real world
xyz = eye(3,4)*info.mat*ijk; 


%---------------------------------------------------------------------
function frame = T2Frame(info,t)

frame = 1 + (t-info.t0)/info.dt;
frame = min(max(round(frame),1),info.nt);

%---------------------------------------------------------------------
function frameselection = Tsel2Framesel(info,tselection)

% Input
frameselection = [];
if isempty(tselection), return, end     % reset

% Convert - new or add - I don't care we scan everything!
for i=1:length(tselection)
    tsel = tselection{i};
    switch length(tsel)
        case 1  % one time point
            framesel = T2Frame(info,tsel);
        case 2  % a time segment
            framesel = T2Frame(info,tsel(1)):T2Frame(info,tsel(2));
        otherwise
            error programming
    end
    frameselection = union(frameselection,framesel);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OTHER TOOLS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function b = isfigoraxeshandle(h)

b = (length(h)==1) && (ishandle(h) || (isnumeric(h) && h>0 && ~mod(h,1)));

%---
function colors = colorset

colors = [0 0 1 ; 0 .5 0 ; 1 0 0 ; 0 .75 .75 ; .75 0 .75 ; .75 .75 0 ; 0 0 0 ; ...
    .75 .35 0 ; 0 1 0 ; 0 .3 0 ; .3 0 0 ; .3 0 .5];


%---
function im = HighlightSelection(im,indselection,clip)
% Input im should be a vertical vector

% make a gray image - first find clipping
if isempty(clip)
    m = min(im);
    M = max(im);
else
    m = clip(1);
    M = clip(2);
end
grey = max(0,min(1,(im-m)/(M-m)));
im = repmat(grey,1,3);

% highlight sets with colors
colors = colorset;
ncolors = size(colors,1);
for i=1:length(indselection)
    indsel = indselection{i};
    % each pixel becomes 67% its original gray color + 33% the
    % highlighting color
    for j=1:3
        im(indsel,j) = (2*im(indsel,j) + colors(mod(i-1,ncolors)+1,j))/3;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEMO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function demo
% show a demo

% make data: - 3D volume using flow, 
% - 2 time evolutions from original volume to a symetrical one 
% - surface using isosurface
% - second time evolution interpolated on that surface
% - 2D spatial gradient of first vertical slice

disp('%This is a demonstration of parts of the ''fn_4Dview'' functionalities.')
disp('%Attention, it will close all windows : press CTRL+C if you want to stop.')
fprintf('\npress any key to continue...'), pause, fprintf(repmat('\b',1,28))
close all

disp('%let''s create a 3D volume:')
disp('[x y z v] = flow;')
[x y z v] = flow;
disp('%v is the data, x,y,z are the spatial coordinates of this data')
disp('%each of v,x,y,z is a 3D 25x50x25 array')
disp('%let''s explore this data!')
fprintf('\npress any key to continue...'), pause, fprintf(repmat('\b',1,28))

disp('fn_4Dview(v)')
fn_4Dview(v)
disp('%try clicking and dragging in the graphs, and clicking on the buttons')
fprintf('\npress any key to continue...'), pause, fprintf(repmat('\b',1,28))

disp('%now let''s create data with a temporal dimension:')
disp('vevol = zeros(25,50,25,11);')     
disp('for i=1:11')
disp('  [xx yy zz w] = flow(25+2*(i-1));')
disp('  vevol(:,:,:,i)=w(i:end-(i-1),1+2*(i-1):end-2*(i-1),i:end-(i-1));')
disp('end')
vevol = zeros(25,50,25,11);
for i=1:11
  [xx yy zz w] = flow(25+2*(i-1));
  vevol(:,:,:,i)=w(i:end-(i-1),1+2*(i-1):end-2*(i-1),i:end-(i-1));
end
disp('%vevol is a 4D 25x50x25x11 array')
disp('%let''s explore it...')
fprintf('\npress any key to continue...'), pause, fprintf(repmat('\b',1,28))

disp('%spatial visualization')
disp('fn_4Dview(''in'',2,vevol)')
disp('%temporal visualization')
disp('fn_4Dview(''in'',3,vevol,''3dplot'')')
fn_4Dview('in',2,vevol)
fn_4Dview('in',3,vevol,'3dplot')
disp('%try clicking and dragging in the plot graph, and clicking on the buttons')
fprintf('\npress any key to continue...'), pause, fprintf(repmat('\b',1,28))

disp('%a single array can even contain several data of the same dimensions,')
disp('%by adding a fifth dimension:')
disp('vevol(:,:,:,:,2) = vevol + rand(size(vevol));')
vevol(:,:,:,:,2) = vevol + rand(size(vevol));
disp('%now, vevol is a 5D 25x50x25x11x2 array')
disp('%let''s explore it')
fprintf('\npress any key to continue...'), pause, fprintf(repmat('\b',1,28))

disp('%spatial visualization, first data component')
disp('fn_4Dview(''in'',2,vevol,''channel'',1)')
disp('%spatial visualization, second data component')
disp('fn_4Dview(''in'',3,vevol,''channel'',2)')
disp('%temporal visualization, both components together')
disp('fn_4Dview(''in'',4,vevol,''3dplot'')')
fn_4Dview('in',2,vevol,'channel',1)
fn_4Dview('in',3,vevol,'channel',2)
fn_4Dview('in',4,vevol,'3dplot')

fprintf('\n\nThe demo is finished, note that additional features exist, while some\nothers are not fully developped yet\n')
return

fprintf('\nnext examples will be given with less explanation...')
fprintf('\npress any key to continue...'), pause, fprintf(repmat('\b',1,81))

disp('close all')
disp('s = isosurface(x, y, z, v, -3);       % s is a mesh, 3104 vertices, 6020 triangles')
disp('sv = interp3(x,y,z,v,s.vertices(:,1),s.vertices(:,2),s.vertices(:,3));')
disp('sv2 = sv + rand(size(sv));')
disp('nv = length(s.vertices);')
disp('svevol = zeros(nv,nt,1);              % svevol dim� are vertices-t-m')
disp('for i=1:nt')
disp('  svevol(:,i)=(nt-i)/(nt-1)*sv+sin((i-1)*sv2/4);')
disp('end')
disp('va = squeeze(vevol(:,:,1,:,1));       % va is a slice, dim� are y-x-t-m')
disp('[vax vay] = gradient(va);')
disp('% 2D image and quiver')
disp('figure(1)')
disp('fn_4Dview(''in'',subplot(2,2,1),''2D'',va(:,:,1))')
disp('fn_4Dview(''in'',subplot(2,2,2),''quiver'',vax(:,:,1),vay(:,:,1),va(:,:,1))')
disp('% quiver + time displayed spatially, 2D + time displayed temporally, time control')
disp('fn_4Dview(''in'',subplot(2,2,3),''quiver'',vax,vay,va)')
disp('fn_4Dview(''in'',subplot(2,2,4),''2dplot'',va)')
disp('fn_4Dview(''in'',2,''timeslider'',1:nt)')
disp('% 3D + time + multiple data, spatial and temporal display')
disp('M = [diag([.2 .25 .25])*[0 1 0; 1 0 0; 0 0 1] [-.1; -3.25; -3.25] ; 0 0 0 1];')
disp('fn_4Dview(''key'',2,''in'',3,''mat'',M,''channel'',1,vevol)')
disp('fn_4Dview(''key'',2,''in'',4,''mat'',M,''channel'',2,vevol)')
disp('figure(5)')
disp('fn_4Dview(''key'',2,''in'',subplot(2,1,1),''mat'',M,''3dplot'',vevol)')
disp('% mesh spatial and temporal display')
disp('fn_4Dview(''key'',2,''in'',6,''mesh'',s,svevol)')
disp('figure(5)')
disp('fn_4Dview(''key'',2,''in'',subplot(2,1,2),''mesh'',s,''3dplot'',svevol)')

close all
s = isosurface(x, y, z, v, -3);       % s is a mesh, 3104 vertices, 6020 triangles
sv = interp3(x,y,z,v,s.vertices(:,1),s.vertices(:,2),s.vertices(:,3));
sv2 = sv + rand(size(sv));
nv = length(s.vertices);
svevol = zeros(nv,11,1);              % svevol dim� are vertices-t-m
for i=1:11
  svevol(:,i)=(11-i)/(11-1)*sv+sin((i-1)*sv2/4);
end
va = squeeze(vevol(:,:,1,:,1));       % va is a slice, dim� are y-x-t-m
[vax vay] = gradient(va);
% 2D image and quiver
figure(1)
fn_4Dview('in',subplot(2,2,1),'2D',va(:,:,1))
fn_4Dview('in',subplot(2,2,2),'quiver',vax(:,:,1),vay(:,:,1),va(:,:,1))
% quiver + time displayed spatially, 2D + time displayed temporally, time control
fn_4Dview('in',subplot(2,2,3),'quiver',vax,vay,va)
fn_4Dview('in',subplot(2,2,4),'2dplot',va)
fn_4Dview('in',2,'timeslider',1:11)
% 3D + time + multiple data, spatial and temporal display
M = [diag([.2 .25 .25])*[0 1 0; 1 0 0; 0 0 1] [-.1; -3.25; -3.25] ; 0 0 0 1];
fn_4Dview('key',2,'in',3,'mat',M,'channel',1,vevol)
fn_4Dview('key',2,'in',4,'mat',M,'channel',2,vevol)
figure(5)
fn_4Dview('key',2,'in',subplot(2,1,1),'mat',M,'3dplot',vevol)
% mesh spatial and temporal display
fn_4Dview('key',2,'in',6,'mesh',s,svevol)
figure(5)
fn_4Dview('key',2,'in',subplot(2,1,2),'mesh',s,'3dplot',svevol)
fprintf('\npress any key to finish...'), pause, fprintf(repmat('\b',1,26)), close all
