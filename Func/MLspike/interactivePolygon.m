classdef interactivePolygon < hgsetget
% function P = interactivePolygon([ha][,'linear|spline'][,'open|closed'][,'points','current'|'init'|p])
%---
% Draw a polygon.
% 
% Example:
%  imagesc                                      % display an image
%  P = interactivePolygon('spline','closed')    % create the object
%  use mouse to initialize,
%  drag to zoom in, right-click to zoom out,
%  double-click to finish initialization,
%  continue to edit by adding/moving/removing points
%  access landmark points in P.points and fine-grain shape in P.points2
%  to erase the drawing, type 'delete(P)'

% Thomas Deneux
% Copyright 2015-2017

    properties (SetAccess = 'private')
        interpmode = 'linear';
        closed = false;
        points = zeros(2,0);    % handle points
        ninterp = 20;
        points2                 % interpolated points
    end
    properties (Access = 'private')
        hf
        ha
        hl          % handle points
        hl2         % interpolated points
    end
    
    methods
        function P = interactivePolygon(varargin)
            % Input -> set properties
            doedit = true;
            i = 0;
            while i<nargin
                i = i+1;
                a = varargin{i};
                if isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')
                    P.ha = a;
                elseif ischar(a)
                    switch a
                        case {'linear' 'spline'}
                            P.interpmode = a;
                        case {'open' 'closed'}
                            P.closed = strcmp(a,'closed');
                        case 'points'
                            i = i+1;
                            P.points = varargin{i};
                        case 'noedit'
                            doedit = false;
                        otherwise
                            error argument
                    end
                else
                    error argument
                end
            end
            if isempty(P.ha), P.ha = gca; end
            P.hf = fn_parentfigure(P.ha);
            
            % Make axes handle visible for waitforbuttonpress to work out
            % Starting point
            if isempty(P.points)
                P.points = getPoint(P);
            elseif strcmp(P.points,'current')
                p = get(P.ha,'currentpoint');
                P.points = p(1,1:2)';
            elseif strcmp(P.points,'init')
                ax = axis(P.ha);
                P.points = fn_add(ax([1 3])',fn_mult([diff(ax(1:2)); diff(ax(3:4))],[.3 .7 .5; .3 .4 .7]));
            end
            P.interpolate(); % compute points2
                
            % Init lines
            P.hl2(1) = line(P.points2(1,:),P.points2(2,:),'parent',P.ha,'hittest','off', ...
                'color','k');
            P.hl2(2) = line(P.points2(1,:),P.points2(2,:),'parent',P.ha,'hittest','off', ...
                'color','w','linestyle',':');
            P.hl = line(P.points(1,:),P.points(2,:),'parent',P.ha,'hittest','off', ...
                'color','k','linestyle','none','marker','.','markersize',10);
                
            % Draw initial poly
            if isvector(P.points)
                % only one point selected yet: let user draw full initial
                % poly
                set(P.hf,'WindowButtonMotionFcn',@(u,e)updateLine(P,'last'))
                while true
                    P.points = P.points(:,[1:end end]); % add a new point
                    getPoint(P)
                    if strcmp(get(P.hf,'SelectionType'),'open')
                        P.points = P.points(:,1:end-1); % last added point is not valid
                        break
                    end
                end
                set(P.hf,'WindowButtonMotionFcn','')
            end
            delete(P.hl2(2))
            P.hl2(2) = [];
            
            % Enable edition
            if doedit
                set(P.hl,'hittest','on','buttondownfcn',@(u,e)editPoints(P,'move/remove'))
                set(P.hl2,'hittest','on','buttondownfcn',@(u,e)editPoints(P,'add'))
            end
        end
        function delete(P)
            delete(P.hl(ishandle(P.hl)))
            delete(P.hl2(ishandle(P.hl2)))
        end
        function editPoints(P,flag)
            p = get(P.ha,'currentpoint'); p = p(1,1:2)';
            uistack([P.hl P.hl2],'top')
            switch flag
                case 'move/remove'
                    switch get(P.hf,'SelectionType')
                        case 'normal'
                            flag = 'move';
                        case 'alt'
                            flag = 'remove';
                        otherwise
                            return
                    end
                    D2 = (get(P.hl,'xdata')-p(1)).^2+(get(P.hl,'ydata')-p(2)).^2;
                    [~, idx] = min(D2);
                    switch flag
                        case 'move'
                            fn_buttonmotion(@()updateLine(P,'idx',idx),'pointer','hand')
                        case 'remove'
                            P.points(:,idx) = [];
                            if isempty(P.points)
                                delete([P.hl P.hl2])
                            else
                                P.updateLine()
                            end
                    end
                case 'add'
                    if ~strcmp(get(P.hf,'SelectionType'),'normal')
                        return
                    end
                    D2 = (get(P.hl2,'xdata')-p(1)).^2+(get(P.hl2,'ydata')-p(2)).^2;
                    [~, idx2] = min(D2);
                    idx = 1 + floor((idx2-1)/P.ninterp);
                    P.points = [P.points(:,1:idx) P.points2(:,idx2) P.points(:,idx+1:end)];
                    fn_buttonmotion(@()updateLine(P,'idx',idx+1),'pointer','hand')
            end
        end
        function p = getPoint(P)
            curfcn = get(P.hf,'WindowButtonDownFcn');
            set(P.hf,'WindowButtonDownFcn',@(u,e)set(P.hf,'WindowButtonDownFcn',''))
            waitfor(P.hf,'WindowButtonDownFcn')
            set(P.hf,'WindowButtonDownFcn',curfcn)
            p = get(P.ha,'currentpoint');
            p = p(1,1:2)';
            if nargout==0, clear p, end
        end
        function updateLine(P,flag,idx)
            if nargin<2, flag = ''; end
            p = get(P.ha,'currentpoint');
            p = p(1,1:2)';
            switch flag
                case ''
                    % nothing to do
                case 'idx'
                    P.points(:,idx) = p;
                case 'last'
                    P.points(:,end) = p;
                otherwise
                    error 'unknown flag'
            end
            P.interpolate(); % compute points2
            set(P.hl,'xdata',P.points(1,:),'ydata',P.points(2,:))            
            set(P.hl2,'xdata',P.points2(1,:),'ydata',P.points2(2,:))            
        end
        function interpolate(P)
            pp = P.points;
            n = size(pp,2);
            if n==1, P.points2 = P.points; return, end
            dx = 1/P.ninterp;
            if strcmp(P.interpmode,'spline') && P.closed
                pp = pp(:,fn_mod([n-1:n 1:n 1:3],n));
                xx = 3:dx:size(pp,2)-2;
            else
                xx = 1:dx:size(pp,2);
            end
            P.points2 = interp1(pp',xx,P.interpmode)';
        end
        function stacktop(P)
            uistack([P.hl P.hl2],'top')
        end
    end
    
    methods (Static)
        function poly = drawpoly(varargin)
            P = interactivePolygon('noedit',varargin{:});
            poly = P.points;
        end
    end
    
end
