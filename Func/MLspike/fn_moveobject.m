function dp = fn_moveobject(hobj,varargin)
% function dp = fn_moveobject(hobj[,'latch'][,'point',i][,'pointer',pointer])
% function dp = fn_moveobject(hobj,vector)
%---
% moves objects while mouse button is pressed
% the second syntax moves the object by a fixed vector
% 
% Options
% - 'latch'     when button is released, brings objects back to initial
%               position
% - 'point',i   move only the ith point(s) of line objects
% - 'twice'     wait for button press+release, or release+pressagain
% - 'x','y'     move in x or y only
% - 'pointer',pointer   image to use for the mouse during motion
% 
% See also fn_buttonmotion, fn_pan

% Thomas Deneux
% Copyright 2007-2017

% Special: move by a fixed vector
if nargin==2 && isnumeric(varargin{1})
    vect = varargin{1};
    for k=1:numel(hobj)
        if isprop(hobj(k),'position')
            posk = get(hobj(k),'position');
            posk(1:2) = posk(1:2) + vect(:)';
            set(hobj(k),'position',posk)
        elseif isprop(hobj(k),'xdata')
            set(hobj(k),'xdata',get(hobj(k),'xdata')+vect(1))
            set(hobj(k),'ydata',get(hobj(k),'ydata')+vect(2))
        else
            error('don''t know how to handle ''%s'' object', ...
                get(hobj(k),'type'))
        end
    end
    return
end

% Input
if ~isvector(hobj) || ~all(ishandle(hobj))
    error('hobj must be a vector of graphic handles')
end
par = fn_get(hobj,'parent');
if ~isscalar(unique([par{:}])), error('objects must have the same parent'), end
% (options)
latchflag = false; twiceflag = false; pointidx = 0; movedir = 'xy'; pointer = [];
i = 1; 
while i<=length(varargin)
    switch varargin{i}
        case 'latch'
            latchflag = true;
        case 'point'
            pointidx = varargin{i+1}; i=i+1;
        case 'twice'
            twiceflag = true;
        case 'pointer'
            pointer = varargin{i+1}; i=i+1;
        case {'x' 'y'}
            movedir = varargin{i};
        otherwise
            error('unknown flag''%''',varargin{i})
    end
    i = i+1;
end

% Referential, units, property changes
switch get(get(hobj(1),'parent'),'type')
    case {'figure','uipanel'}
        % pointer location will be in screen referential (pixel units), so
        % change 'units' property of objects to 'pixel'
        ref = 0;
        oldunits = fn_get(hobj,'units');
        set(hobj,'units','pixels')
    case {'axes'}
        % pointer location will be in axes referential
        ref = get(hobj(1),'parent');
    otherwise
        error('cannot handle parent type ''%s''',get(get(hobj(1),'parent'),'type'))
end

% Find parent figure
hf = get(hobj(1),'parent');
while ~strcmp(get(hf,'type'),'figure'), hf = get(hf,'parent'); end

% Moving object while button is pressed
p0 = getpoint(ref);
pos0 = getpos(hobj,ref);
fn_buttonmotion({@movesub,hobj,ref,p0,pos0,pointidx,movedir},hf,'pointer',pointer)
if twiceflag
    fn_buttonmotion({@movesub,hobj,ref,p0,pos0,pointidx,movedir},hf,'pointer',pointer)
end

% Restore properties
if latchflag, setpos(hobj,ref,p0,pos0,p0,pointidx,movedir), end
if strcmp(get(ref,'type'),'root')
    fn_set(hobj,'units',oldunits)
end

% output
if nargout>0
    p = getpoint(ref);
    dp = p-p0;
end

%---
function movesub(hobj,ref,p0,pos0,pointidx,movedir)

p = getpoint(ref);
setpos(hobj,ref,p0,pos0,p,pointidx,movedir)
drawnow expose

%---
function p = getpoint(ref)

if strcmp(get(ref,'type'),'root')
    p = get(ref,'pointerlocation');
else
    p = get(ref,'currentpoint');
    p = p(1,1:2);
end

%---
function pos = getpos(hobj,ref)

if strcmp(get(ref,'type'),'root')
    pos = fn_get(hobj,'position');
else
    nobj = length(hobj);
    pos = cell(1,nobj);
    for k=1:nobj
        if isprop(hobj(k),'position')
            pos{k} = get(hobj(k),'position');
        elseif isprop(hobj(k),'xdata')
            pos{k} = get(hobj(k),{'xdata','ydata'});
        else
            error('don''t know how to handle ''%s'' object', ...
                get(hobj(k),'type'))
        end
    end
end

%---
function setpos(hobj,ref,p0,pos0,p,pointidx,movedir)

dp = p(1,1:2)-p0;
if strcmp(movedir,'x'), dp(2)=0; elseif strcmp(movedir,'y'), dp(1)=0; end
for k=1:length(hobj)
    posk = pos0{k};
    if isnumeric(posk)
        posk(1:2) = posk(1:2) + dp;
        set(hobj(k),'position',posk)
    else
        if pointidx
            posk{1}(pointidx)=posk{1}(pointidx)+dp(1);
            posk{2}(pointidx)=posk{2}(pointidx)+dp(2);
        else
            posk{1}=posk{1}+dp(1);
            posk{2}=posk{2}+dp(2);
        end
        set(hobj(k),{'xdata' 'ydata'},posk)
    end
end



