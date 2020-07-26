classdef fn_slider < hgsetget
    % function fn_slider([hp,][properties])
    %---
    % Slider
    %
    % Detail on some properties:
    % - mode    'point' [default], 'area' or 'area+point'
    % - layout  'auto' [default], 'left', 'right', 'up' or 'down'
    % - scrollwheel     'off' [default], 'on' or 'default'
    %
    % Use setInteger(U,n[,0]) to set all properties so that possible values
    % will be integers from 1 to n (add ,0 for 0 to n-1 instead).
    %
    % See also fn_sliderenhance, fn_sensor, fn_control
    
    % Thomas Deneux
    % Copyright 2007-2017
    properties
        inc = 0;
        minmax = [0 1];
    end
    properties (Dependent)
        mode        % 'point', 'area', or 'area+point'
        value       % scalar in 'point' mode, 2-element vector in 'area' or 'area+point' mode
        point       % scalar in 'area+point' mode, [] otherwise
        width
        stepsize
        sliderstep
        min
        max
    end
    properties (Dependent, GetAccess='private')
        steps
        scrollwheel
    end
    properties
        callback
        deletefcn
    end
    properties (Dependent)
        parent
        units
        position
        foregroundcolor
        backgroundcolor
        slidercolor
        visible
    end
    properties
        layout = 'auto';    % 'left', 'right', 'up', 'down' or 'auto'
        enabled = true;
    end
    properties (SetAccess='private')
        sliderscrolling = false;
        posframepix;
    end
    properties (Access='private')
        hf              % figure
        hpanel          % uipanel
        hframe          % frame around panel
        hslider         % uicontrol, frame style
        hline           % line, this is a second slider in fact
        menu            % context menu
        menuitems       % its childs
        initialized = false; % will be set to true once initialized: then only position will be actually updated
    end
    properties (Access='private')
        area = 1;
        x = [.25 .75];  % relative values; [left right] in 'area' mode, [nstepcur nstepmax] in 'point' mode
    end
    properties (Dependent, Access='private')
        sides
        left           
        right           
        center      
        pointpos
    end
    
    % Constructor/Destructor
    methods
        function U = fn_slider(varargin)
            % Objects
            if nargin>0
                a = varargin{1};
                if isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'uipanel')
                    U.hpanel = a;
                    varargin(1)=[];
                end
            end
            if isempty(U.hpanel)
                % 'parent' property specified in arguments?
                hpar = [];
                for k=1:nargin
                    if isequal(varargin{k},'parent')
                        hpar = varargin{k+1};
                        varargin([k k+1])=[];
                        break
                    end
                end
                if isempty(hpar), hpar = gcf; end
                U.hpanel = uipanel('parent',hpar, ...
                    'units','pixel','position',[20 20 200 20]);
            end
            getnewframepos(U)
            set(U.hpanel,'bordertype','line','borderwidth',0, ...
                'resizefcn',@(u,evnt)getnewframepos(U))
            U.hframe = uicontrol('parent',U.hpanel, ...
                'style','frame','enable','off', ...
                'units','normalized','position',[0 0 1 1]);
            U.hslider = uicontrol('parent',U.hpanel, ...
                'style','frame','enable','off', ...
                'units','normalized');
            U.hline = uicontrol('parent',U.hpanel, ...
                'style','frame','enable','off','visible','off', ...
                'units','pixels');
            U.foregroundcolor = [0 0 0];
            U.slidercolor = [.3 .4 .5];
            U.hf = get(U.hpanel,'parent');
            while ~strcmp(get(U.hf,'type'),'figure'), U.hf = get(U.hf,'parent'); end
            
            % Callbacks
            set(U.hframe,'buttondownfcn',@(u,evnt)event(U,'frame'))
            set(U.hslider,'buttondownfcn',@(u,evnt)event(U,'slider'))
            set(U.hline,'buttondownfcn',@(u,evnt)event(U,'line'))
            
            % Delete functions
            U.deletefcn = get(U.hpanel,'deletefcn');
            set([U.hpanel U.hframe U.hslider U.hline],'deletefcn',@(u,e)delete(U))
            
            % Context menu (for scroll wheel)
            initlocalmenu(U)
            
            % User settings
            if ~isempty(varargin), set(U,varargin{:}), end
            U.initialized = true;
           
            % Set position
            sliderposition(U)
        end
        function delete(U)
            if ~isempty(U.deletefcn)
                fn_evalcallback(U.deletefcn,U.hpanel,[])
                U.deletefcn = '';
            end
            if ishandle(U.hpanel)
                objs = [U.hpanel U.hframe U.hslider U.hline];
                set(objs(ishandle(objs)),'deletefcn','')
                delete(U.hpanel)
            end
        end
    end
    
    % GET/SET - basic object properties
    methods
        function str = get.mode(U)
            switch U.area
                case 0
                    str = 'point';
                case 1
                    str = 'area';
                case 2
                    str = 'area+point';
            end
        end
        function x = get.visible(U)
            x = get(U.hpanel,'visible');
        end
        function set.visible(U,x)
            set(U.hpanel,'visible',x)
        end
        function hp = get.parent(U)
            hp = get(U.hpanel,'parent');
        end
        function c = get.foregroundcolor(U)
            c = get(U.hframe,'foregroundcolor');
        end
        function set.foregroundcolor(U,c)
            set([U.hframe U.hslider U.hline],'foregroundcolor',c);
        end
        function c = get.backgroundcolor(U)
            c = get(U.hpanel,'backgroundcolor');
        end
        function set.backgroundcolor(U,c)
            set([U.hpanel U.hframe],'backgroundcolor',c);
        end
        function c = get.slidercolor(U)
            c = get(U.hslider,'backgroundcolor');
        end
        function set.slidercolor(U,c)
            set(U.hslider,'backgroundcolor',c);
        end
        function pos = get.units(U)
            pos = get(U.hpanel,'units');
        end
        function set.units(U,pos)
            set(U.hpanel,'units',pos);
        end
        function pos = get.position(U)
            pos = get(U.hpanel,'position');
        end 
        function set.position(U,pos)
            if all(pos==get(U.hpanel,'pos')), return, end
            set(U.hpanel,'position',pos);
            sliderposition(U)
        end
    end
    
    % GET/SET - positions
    methods
        function getnewframepos(U)
            tmp = get(U.hpanel,'units');
            set(U.hpanel,'units','pixel');
            U.posframepix = get(U.hpanel,'position');
            set(U.hpanel,'units',tmp)
        end
        function sliderposition(U)
            % position the slider inside the frame
 
            % set position only once after all initializations have ended
            if ~U.initialized, return, end
            
            % normalized position
            [isvertical iscoordinv] = orientation(U);
            sid = U.sides;
            if iscoordinv, sid = [1-sid(2) 1-sid(1)]; end
            xpos = [sid(1) diff(sid)];
            % actual position
            if isvertical
                pos = [0 xpos(1) 1 max(xpos(2),1/U.posframepix(4))];
            else
                pos = [xpos(1) 0 max(xpos(2),1/U.posframepix(3)) 1];
            end
            % update display if possible
            set(U.hslider,'position',pos)
            % update line as well if mode area+point
            if U.area==2, lineposition(U), end
            % try to handle a bug: sometimes hslider is not visible; the
            % following lines seem to be working
            if ~U.sliderscrolling
                if fn_dodebug
                    %disp('trying not to bring slider to top any more to save time')
                else
                    uistack(U.hslider,'top')
                    if U.area==2, uistack(U.hline,'top'), end
                end
            end
        end
        function lineposition(U)
            % position the small line (case U.area=2) inside the frame
            if U.area~=2, set(U.hline,'visible','off'), return, end
            % normalized position
            xpos = U.pointpos;
            [isvertical iscoordinv] = orientation(U);
            if iscoordinv, xpos = 1-xpos; end
            % line has a width of 2 pixels, so it is more convenient to
            % work in pixel units
            if isvertical
                xpospix = xpos*U.posframepix(4);
                pos = [1 xpospix-1 U.posframepix(3) 2];
            else
                xpospix = xpos*U.posframepix(3);
                pos = [xpospix-1 1 2 U.posframepix(4)];
            end
            % update display if possible
            if diff(U.minmax)
                set(U.hline,'visible','on','position',pos)
            end
        end
        function set.x(U,x)
            % coerce
            if U.inc, ninc = round(1/U.inc); end %#ok<*MCSUP>
            switch U.area
                case 0
                    % x(1) current number of x-steps, x(2) is total number of x-steps
                    if x(2)<0 || isinf(x(2)) || isnan(x(2))
                        error 'number of steps must be >=0'
                    end
                    x(1) = max(0,min(x(2),x(1)));
                    if U.inc
                        % rounding usually divides steps (not necessarily
                        % though, in particular when some properties are
                        % not set correctly yet)
                        nincperstep = ninc/x(2);
                        x(1) = round(x(1)*nincperstep)/nincperstep;
                    end
                case 1
                    % x(1) is left, x(2) is right
                    x = max(0,min(1,x));
                    e = 1e-2;
                    if diff(x)<=0
                        if x(1)==U.x(1) || x(1)<e
                            x(2) = x(1)+e;
                        elseif x(2)==U.x(2) || x(2)>1-e
                            x(1) = x(2)-e;
                        else
                            x = mean(x)+[-.5 .5]*1e-2;
                        end
                    end
                    if U.inc
                        x = round(x*ninc)/ninc;
                    end
                case 2
                    % x(1) is left, x(2) is right, x(3) is relative value
                    if diff(x(1:2))<0, x = x([2 1]); end
                    x = min(1,max(0,x));
                    % TODO: change set.mode so that the case that
                    % length(x)==2 in 'area+point' mode will not happen
                    if length(x)<3
                        x(3) = mean(x);
                    else
                        x(3) = max(x(1),min(x(2),x(3)));
                    end
                    if U.inc
                        x = round(x*ninc)/ninc;
                    end
            end
            % set
            if isequal(x,U.x), return, end
            U.x = x;
            % update display
            sliderposition(U)
        end
        function left = get.left(U)
            if U.area
                left = U.x(1);
            else
                w = U.width;
                if U.x(2)
                    left = (U.x(1)/U.x(2))*(1-w);
                else
                    left = 0;
                end
            end
        end
        function set.left(U,left)
            if U.area
                U.x(1) = left;
            else
                error('cannot set left in ''point'' mode')
            end
        end
        function right = get.right(U)
            if U.area
                right = U.x(2);
            else
                w = U.width;
                if U.x(2)
                    right = (U.x(1)/U.x(2))*(1-w) + w;
                else
                    right = 1;
                end
            end
        end
        function set.right(U,right)
            if U.area
                U.x(2) = right;
            else
                error('cannot set right in ''point'' mode')
            end
        end
        function sides = get.sides(U)
            if U.area
                sides = U.x(1:2);
            else
                w = U.width;
                if U.x(2)
                    sides = (U.x(1)/U.x(2))*(1-w) + [0 w];
                else
                    sides = [0 1];
                end
            end
        end
        function set.sides(U,sides)
            w = diff(sides);
            if w<=0, error 'width must be >0', end
            if U.area
                U.x(1:2) = sides;
            else 
                nval = 1/w; nstep = nval-1;
                U.x = [sides(1)/(1-w)*nstep nstep];
            end
        end
        function c = get.center(U)
            if U.area
                c = mean(U.x);
            else
                w = U.width;
                c = (U.x(1)/U.x(2))*(1-w) + w/2;
            end
        end
        function set.center(U,c)
            if U.area
                w = diff(U.x(1:2));
                xnew = c + [-w/2 w/2];
                % do not allow width to change! (refuse to move center more
                % than a certain quantity)
                if xnew(1)<0
                    xnew = xnew-xnew(1);
                elseif xnew(2)>1
                    xnew = xnew-(xnew(2)-1);
                end
                U.x(1:2) = xnew;
            else
                w = U.width;
                U.x(1) = (c-w/2)*U.x(2)/(1-w);
            end
        end
        function p = get.pointpos(U)
            if U.area==2
                p = U.x(3);
            else
                p = [];
            end                
        end
        function set.pointpos(U,p)
            if U.area==2
                U.x(3) = p;
            else
                error('''pointpos'' property can be set only in ''area+point'' mode')
            end                
        end
        function set.layout(U,x)
            if ~fn_ismemberstr(x,{'left' 'right' 'up' 'down' 'auto'})
                error 'not a valid layout flag'
            end
            if strcmp(x,U.layout), return, end
            % set property value
            U.layout = x;
            % update display
            sliderposition(U)
        end
    end
    
    % GET/SET - active properties
    methods
        function setInteger(U,n,istart)
            if nargin<3, istart = 1; end
            U.mode = 'point';
            U.minmax = istart+[0 n-1];
            U.x(2) = n-1;
            U.inc = 1/(n-1);
        end
        function set.mode(U,str)
            if strcmp(str,U.mode), return, end
            % memorize position
            sid = U.sides;
            % update mode
            switch str
                case 'point'
                    U.area = 0;
                case 'area'
                    U.area = 1;
                case 'area+point'
                    U.area = 2;
                otherwise
                    error('wrong mode ''%s''',str)
            end
            % update value storage (U.x) by re-setting the position
            % this works in the case of 'area+point' mode, but it is
            % tricky, see set.x function
            U.sides = sid;
            % hide the line if needed
            if U.area~=2, set(U.hline,'visible','off'), end
        end     
        function set.inc(U,inc)
            if inc && mod(1,inc)
                error('rounding increment must divide 1')
            end
            U.inc = double(inc);
            U.x = U.x; % automatic update! (coerce)
        end
        function width = get.width(U)
            if U.area
                width = diff(U.x(1:2));
            else
                nval = U.x(2)+1;
                w = 1/nval;
                % 'point' mode: slider must have a minimal width of 10 pixels
                isvertical = orientation(U);
                W = 10;
                fact = U.posframepix(fn_switch(isvertical,4,3));
                width = max(W/fact,w);
            end
        end
        function set.width(U,width)
            width = double(width);
            if U.area
                if U.inc
                    % amount by which increase/decrease should be a multiple of
                    % the rounding
                    width = round(width/U.inc)*U.inc;
                end
                w = width;
                % try to preserve center
                c = U.center;
                xnew = c + [-w/2 w/2];
                if xnew(1)<0
                    xnew = xnew-xnew(1);
                elseif xnew(2)>1
                    xnew = xnew-(xnew(2)-1);
                end
                U.x(1:2) = xnew;
            else
                % warning: this sets the 'functional width'; if it is too
                % small, the actual display width will be larger
                val = U.value;
                nval = 1/width; nstep = nval-1;
                U.x(2) = nstep;
                U.value = val; % this re-adjusts U.x(1)
            end
        end
        function step = get.stepsize(U)
            if U.area
                step = diff(U.x(1:2));
            else
                step = 1/U.x(2);
            end
        end
        function set.stepsize(U,step)
            step = double(step);
            if U.area
                U.width = step;
            else
                U.x(2) = 1/step;
            end
        end
        function x = get.sliderstep(U)
            if U.area
                x = [U.inc U.width];
            else
                x = [U.inc 1/U.x(2)];
            end
        end
        function set.sliderstep(U,sliderstep)
            sliderstep = double(sliderstep);
            U.inc = sliderstep(1);
            U.stepsize = sliderstep(2);
        end
        function val = get.value(U)
            if U.area
                val = U.min + U.x(1:2)*diff(U.minmax);
            else
                if U.x(2)==0
                    val = U.min;
                else
                    val = U.min + U.x(1)*diff(U.minmax)/U.x(2);
                end
            end
        end
        function set.value(U,val)
            if all(val==U.value), return, end
            d = diff(U.minmax);
            if d==0
                if U.area,
                    U.x(1:2) = [0 1];
                else
                    U.x(1) = 0;
                end
            else
                v = (double(val)-U.min) / d;
                if U.area
                    U.x(1:2) = v;
                else
                    U.x(1) = v*U.x(2);
                end
            end
        end
        function val = get.point(U)
            if U.area==2
                v = U.pointpos;
            else
                v = [];
            end
            val = U.min + v*diff(U.minmax);
        end
        function set.point(U,val)
            if U.area~=2
                error('''pointpos'' property can be set only in ''area+point'' mode')
            end
            if val==U.point, return, end
            d = diff(U.minmax);
            if d==0
                U.pointpos = .5;
            else
                v = (double(val)-U.min) / diff(U.minmax);
                U.pointpos = v;
            end
        end
        function set.minmax(U,mM)
            if all(mM==U.minmax), return, end
            % memorize value
            val = U.value;
            p = U.point;
            % change min-max
            U.minmax = double(mM);
            % re-set value
            U.value = val;
            if U.area==2, U.point = p; end
            % invisible slider part if min==max
            set(U.hslider,'visible',fn_switch(diff(mM)))
        end
        function set.steps(U,steps)
            % valid only in 'point' mode
            if U.area, error 'set.steps method can be used only in ''point'' mode', end
            % memorize value
            val = U.value;
            % steps
            steps = double(steps);
            if isscalar(steps), mM = [1 steps]; else mM = steps(1:2); end
            if length(steps)==3, step = steps(3); else step = 1; end
            nstep = diff(mM)/step;
            if mod(nstep,1), error 'number of steps is not integer', end
            % set properties
            U.minmax = mM;
            U.inc = 1/nstep;
            U.x(2) = nstep;
            % re-set value
            U.value = val;
            % invisible slider part if min==max
            set(U.hslider,'visible',fn_switch(diff(mM)))
        end
        function m = get.min(U)
            m = U.minmax(1);
        end
        function set.min(U,m)
            U.minmax(1) = m;
        end
        function M = get.max(U)
            M = U.minmax(2);
        end
        function set.max(U,M)
            U.minmax(2) = M;
        end
    end
    
    % GET/SET - scroll wheel
    methods
        function set.scrollwheel(U,flag)
            switch flag
                case 'on'
                    fn_scrollwheelregister(U.hpanel,@(n)event(U,'scroll',n))
                case 'default'
                    fn_scrollwheelregister(U.hpanel,@(n)event(U,'scroll',n),'default')
                case 'off'
                    fn_scrollwheelregister(U.hpanel,flag)
                otherwise
                    error 'scrollwheel value must be ''off'', ''on'' or ''default'''
            end
        end
    end
    
    % Callbacks
    methods
        function event(U,flag,nscroll)
            if ~U.enabled, return, end
            % special case: double-click in area mode
            if U.area && strcmp(flag,'slider') ...
                    && strcmp(get(U.hf,'selectiontype'),'open')
                flag = 'zoomreset';
            end
            switch flag
                case 'scroll'
                    % scroll wheel
                    [isvert isinv] = orientation(U);
                    if ~isinv, nscroll = -nscroll; end
                    if ~isvert, nscroll = -nscroll; end
                    if U.area
                        U.center = U.center + nscroll*U.width;
                    else
                        U.x(1) = U.x(1) + nscroll;
                    end
                case 'frame'
                    % step the slider
                    xf = mouseposframe(U);
                    dir = 2*(xf>U.center)-1;
                    if U.area
                        U.center = U.center + dir*U.width;
                    else
                        U.x(1) = U.x(1) + dir;
                    end
                case 'zoomreset'
                    U.width = 1;
                otherwise
                    % slide
                    p0 = mouseposframe(U);
                    if strcmp(flag,'slider') && U.area
                        PIX = 4;
                        xs = mouseposslider(U);
                        if xs(1)<=PIX
                            flag = 'left';
                        elseif xs(2)>=-PIX
                            flag = 'right';
                        end
                    end
                    switch flag
                        case 'left'
                            % move the 'left' side of the slider (i.e.
                            % really its left side if layout is 'right',
                            % but its right side if layout is 'left',
                            % its bottom side if layout is 'up',
                            % and its top side if layout is 'down')
                            pos0 = U.left;
                            [isvert isinv] = orientation(U);
                            set(U.hf,'pointer',fn_switch([isvert isinv], ...
                                [0 0],'left',[0 1],'right',[1 0],'bottom',[1 1],'top'))
                        case 'right'
                            % move the 'right' side of the slider
                            pos0 = U.right;
                            [isvert isinv] = orientation(U);
                            set(U.hf,'pointer',fn_switch([isvert isinv], ...
                                [0 0],'right',[0 1],'left',[1 0],'top',[1 1],'bottom'))
                        case 'slider'
                            % move the slider
                            pos0 = U.center;
                        case 'line'
                            % move the line
                            pos0 = U.pointpos;
                    end
                    U.sliderscrolling = true;
                    fn_buttonmotion({@slide,U,flag,p0,pos0},U.hf)
                    U.sliderscrolling = false;
                    if U.area==2 && U.center==pos0
                        % now sliding -> step the line
                        dir = 2*(p0>U.pointpos)-1;
                        step = fn_switch(U.inc~=0,U.inc,U.width/10);
                        U.pointpos = U.pointpos + dir*step;
                    end
                    set(U.hf,'pointer','arrow') % pointer has been modified when moving the edges
            end
            exec(U)
        end
        function slide(U,flag,p0,pos0)
            oldval = U.value;
            p = mouseposframe(U);          
            switch flag
                case 'left'
                    U.left = p;
                    if ~isequal(U.value,oldval), exec(U), end
                case 'right'
                    U.right = p;
                    if ~isequal(U.value,oldval), exec(U), end
                case 'slider'
                    U.center = pos0+(p-p0);
                    if ~isequal(U.value,oldval), exec(U), end
                case 'line'
                    oldval = U.pointpos;
                    U.pointpos = pos0+(p-p0);
                    if ~isequal(U.pointpos,oldval), exec(U), end
            end
        end
        function exec(U)
            fun = U.callback; % very surprisingly, getting U.callback takes 0.05s, so better do it only once
            if isempty(fun), return, end
            switch class(fun)
                case 'char'
                    evalin('base',fun)
                case 'function_handle'
                    feval(fun,U,[]);
                case 'cell'
                    feval(fun{1},U,[],fun{2:end})
            end
        end
    end
    
    % Routines
    methods
        function [isvertical iscoordinv] = orientation(U)
            ori = U.layout;
            if strcmp(ori,'auto')
                pos = U.posframepix;
                ori = fn_switch(pos(4)>pos(3),'up','right');
            end
            isvertical = fn_ismemberstr(ori,{'up' 'down'});
            iscoordinv = fn_ismemberstr(ori,{'left' 'down'});
        end
        function x = mouseposframe(U)
            % normalized position inside frame
            pos = mousepos(U.hpanel);
            [isvertical iscoordinv] = orientation(U);
            if isvertical
                x = (pos(2)-1) / U.posframepix(4);
            else
                x = (pos(1)-1) / U.posframepix(3);
            end
            if iscoordinv
                x = 1-x;
            end
        end
        function x = mouseposslider(U)
            % pixel positions relative to left and right sides of slider
            pos = mousepos(U.hpanel);
            set(U.hslider,'units','pixels')
            posframe = get(U.hslider,'position');
            set(U.hslider,'units','normalized')
            [isvertical iscoordinv] = orientation(U);
            if isvertical
                x = [pos(2)-posframe(2) pos(2)-(posframe(2)+posframe(4))];
                x = x+1; % BERK
            else
                x = [pos(1)-posframe(1) pos(1)-(posframe(1)+posframe(3))];
            end
            if iscoordinv
                x = -x([2 1]);
            end
        end
    end
    
    % Context menu
    methods
        function initlocalmenu(U)
            delete(U.menu)
            m = uicontextmenu('parent',U.hf);
            U.menu = m;
            set([U.hframe U.hslider U.hline],'uicontextmenu',m)
            
            % scroll wheel
            uimenu(m,'label','scroll wheel off', ...
                'callback',@(u,e)set(U,'scrollwheel','off'))
            uimenu(m,'label','scroll wheel on (mouse on object)', ...
                'callback',@(u,e)set(U,'scrollwheel','on'))
            uimenu(m,'label','scroll wheel on (default in figure)', ...
                'callback',@(u,e)set(U,'scrollwheel','default'))
        end
    end
end

function pos = mousepos(hobj)
% position in pixel units of pointer in current container (figure or
% uipanel)

hf = fn_parentfigure(hobj);
pos = get(hf,'CurrentPoint');
if strcmp(get(hobj,'type'),'uipanel')
    panelpos = round(fn_pixelpos(hobj,'recursive'));
    pos = pos-panelpos(1:2);
end

end