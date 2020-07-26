function varargout = fn_coordinates(varargin)
% function [orig scale] = fn_coordinates([handle,]refchangetag)
% function x2 = fn_coordinates([handle,]refchangetag,x1,'position')
% function v2 = fn_coordinates([handle,]refchangetag,v1,'vector')
%---
% Change coordinates between screen (pixels), figure, axes
% The "referential change tag" will be 's2f', 'f2a', ...
% Possible referentials are:
% - s       screen, bottom-left origin, pixel units
% - f       figure, bottom-left origin, normalized units
% - g       figure, bottom-left origin, pixel units
% - a       axes, axes units
% - b       axes, bottom-left origin, pixel units
% - c       axes, bottom-left origin, normalized units
% 
% Ex: the axes coordinates of the point at position 10 pixels to the right 
% and the top of the axes origin in figure 1 are
% xy = fn_coordinates(1,'b2a',[10 10],'position')

% Thomas Deneux
% Copyright 2007-2017

if nargin<1, help fn_coordinates, return, end

% Input
narg = nargin;
if ishandle(varargin{1})
    h = varargin{1};
    varargin(1) = [];
    narg = narg-1;
    switch get(h,'type')
        case 'figure'
            hf = h; ha = [];
        case 'axes'
            ha = h; hf = get(ha,'parent');
        otherwise
            error('handle is not figure or axes')
    end
    clear h
else
    hf = gcf; ha = [];
end
refchangetag = varargin{1};
if narg>1
    x = varargin{2};
    if size(x,1)==1, x=x'; end
    if size(x,1)~=2, error('coordinates should be a 2-element vector or a 2-rows array'); end
    valuetag = varargin{3};
else
    valuetag = 'transformation';
end

% screen to figure (or uipanel...) conversions
posf = fn_pixelpos(hf);
origf = posf(1:2);
scalef = posf(3:4);
Mf2s = transf2mat(origf,scalef);
Mg2s = transf2mat(origf-1,[1 1]); %#ok<*NASGU>

% figure to axes conversion
if any(ismember('abc',refchangetag))
    if isempty(ha), ha=gca; end
    haunits = get(ha,'units');
    switch haunits
        case 'normalized'
            posa = get(ha,'position');
        case 'pixels'
            % direct computation is better than changing the units if there
            % are listener to 'units' or to 'position'
            posa = get(ha,'position');
            posa = [(posa(1:2)-1)./scalef posa(3:4)./scalef];
        otherwise
            % don't know how to do the calculations -> switch
            set(ha,'units','normalized')
            posa = get(ha,'position');
            set(ha,'units',haunits)
    end
    axa = double(axis(ha));
    centera = posa(1:2) + posa(3:4)/2;
    sizea = posa(3:4);
    scalea = sizea ./ [axa(2)-axa(1) axa(4)-axa(3)];
    % if DataAspectRatioMode is manual, then only part of the axes might be
    % occupied!! let's see which dimension is not fully occupied
    if strcmp(get(ha,'dataaspectratiomode'),'manual')
        ratio = get(ha,'dataaspectratio');
        manualratio = ratio(2)/ratio(1); % yes, it is the opposite of what i thougt...
        scalea2s = scalea.*scalef;
        autoratio = scalea2s(1)/scalea2s(2);
        change = manualratio/autoratio;
        if change>1
            % we want a larger x/y ratio than given by the full axes
            % -> shrink y dimension
            scalea(2) = scalea(2)/change;
            sizea(2) = sizea(2)/change;
        else
            % the contrary
            scalea(1) = scalea(1)*change;
            sizea(1) = sizea(1)*change;
        end
    end
    leftbottom = axa([1 3]);
    if strcmp(get(ha,'xdir'),'reverse');
        scalea(1) = -scalea(1);
        leftbottom(1) = axa(2);
    end
    if strcmp(get(ha,'ydir'),'reverse');
        scalea(2) = -scalea(2);
        leftbottom(2) = axa(4);
    end
    axcenter = (axa([1 3])+axa([2 4]))/2;
    origa = centera - axcenter.*scalea;
    Ma2f = transf2mat(origa,scalea);
    Ma2s = Mf2s*Ma2f;
    leftbottom2s = Ma2s*[leftbottom 1]';
    Mb2s = transf2mat(leftbottom2s([1 2]),[1 1]);
    leftbottom2f = Ma2f*[leftbottom 1]';
    Mc2f = transf2mat(leftbottom2f([1 2]),sizea);
    Mc2s = Mf2s*Mc2f;
end

% transformation matrix is computed using screen as intermediary
% referential
% use some trick with eval!!! DON'T CHANGE VARIABLE NAMES IN THIS CODE!
Ms2s = eye(3);
M1 = eval(['M' refchangetag(1) '2s']);
M2 = eval(['M' refchangetag(3) '2s']);
M = M2^-1 * M1;

% computations
switch valuetag
    case 'transformation'
        [varargout{1:nargout}] = mat2transf(M);
    case 'vector'
        varargout = {M(1:2,1:2)*x};
     case 'position'
        x(3,:) = 1;
        x2 = M*x;
        % round correctly if target referential is figure with pixel units
        if refchangetag(3)=='g'
            x2(1,:) = round(x2(1,:));
            x2(2,:) = 1e4 - round(1e4-x2(2,:));
        end
        varargout = {x2(1:2,:)};
    otherwise
        error('wrong flag ''%s''',valuetag)
end       

%---
function M = transf2mat(orig,scale)

M = [scale(1) 0 orig(1); 0 scale(2) orig(2); 0 0 1];

%--- 
function [orig, scale] = mat2transf(M)

orig = [M(1,3) M(2,3)];
scale = [M(1,1) M(2,2)];
