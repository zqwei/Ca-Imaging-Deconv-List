classdef fn_stepper < hgsetget
    % function fn_stepper([n,][properties])
    % See also fn_slider, fn_control
    
    % Thomas Deneux
    % Copyright 2008-2017
    
    properties
        nx
        value
        step
        coerce
        min
        max
        format
        callback
        deletefcn
    end
    properties (Dependent)
        units
        position
        foregroundcolor
        backgroundcolor
        visible
        enable
    end
    properties (SetAccess='private')
        parent
        hpanel          % uipanel
    end
    properties (Access='private')
        hslider
        htext
        doset = false;
    end
    
    % Constructor/Destructor
    methods
        function P = fn_stepper(varargin)
            % Number of steppers
            if mod(nargin,2)
                P.nx = varargin{1};
                varargin(1) = [];
            else
                % try to guess how many values if value is provided
                f = find(strcmpi(varargin(1:2:end),'value'));
                if isempty(f)
                    P.nx = 1;
                else
                    P.nx = length(varargin{2*f});
                end
            end
            
            % Min and max, format
            P.doset = false; % avoid automatic set actions
            P.value = zeros(1,P.nx);
            P.step = 1;
            P.coerce = false;
            P.min = -Inf;
            P.max =  Inf;
            P.format = '%.2g';
            P.doset = true;
            
            % Objects
            % parent -> any instruction about parent?
            f = find(strcmpi(varargin(1:2:end),'parent'));
            if isempty(f)
                P.parent = gcf;
            else
                P.parent = varargin{2*f};
                varargin(2*f-1:2*f) = [];
            end
            % panel
            P.hpanel = uipanel('parent',P.parent, ...
                'units','pixel','position',[100 100 100 30], ...
                'bordertype','none');
            fn_pixelsizelistener(P.hpanel,@(u,e)updateinternposition(P));
            % sliders and text fields - for the moment, use only normalized
            % positionning
            P.hslider = zeros(1,P.nx);
            P.htext   = zeros(1,P.nx);
            for k=1:P.nx
                P.hslider(k) = uicontrol('parent',P.hpanel,'style','slider', ...
                    'units','pixel', ...
                    'value', 0, 'min', -1, 'max', 1, 'sliderstep', [.5 .5], ...
                    'callback', @(u,e)chgvalue(P,k,'slider'));
                P.htext(k)   = uicontrol('parent',P.hpanel,'style','edit', ...
                    'units','pixel', ...
                    'string', '0', 'horizontalalignment', 'center',  ...
                    'callback', @(u,e)chgvalue(P,k,'text'));
            end
            updateinternposition(P);
            
            % User settings
            if ~isempty(varargin), set(P,varargin{:}), end
        end
        function delete(P)
            if ishandle(P.hpanel), delete(P.hpanel), end
        end
    end
    
    % GET/SET - basic object properties
    methods
        function x = get.visible(P)
            x = get(P.hpanel,'visible');
        end
        function set.visible(P,x)
            set(P.hpanel,'visible',x)
        end
        function x = get.enable(P)
            x = get(P.htext,'visible');
        end
        function set.enable(P,x)
            set([P.hslider P.htext],'visible',x)
        end
        function x = get.deletefcn(P)
            x = get(P.hpanel,'deletefcn');
        end
        function set.deletefcn(P,x)
            set(P.hpanel,'deletefcn',x) 
        end
        function c = get.foregroundcolor(P)
            c = get(P.hpanel,'foregroundcolor');
        end
        function set.foregroundcolor(P,c)
            set([P.hpanel P.hslider P.htext],'foregroundcolor',c);
        end
        function c = get.backgroundcolor(P)
            c = get(P.hpanel,'backgroundcolor');
        end
        function set.backgroundcolor(P,c)
            set([P.hpanel P.hslider P.htext],'backgroundcolor',c);
        end
        function u = get.units(P)
            u = get(P.hpanel,'units');
        end
        function set.units(P,u)
            set(P.hpanel,'units',u);
        end
        function pos = get.position(P)
            pos = get(P.hpanel,'position');
        end 
        function set.position(P,pos)
            set(P.hpanel,'position',pos);
        end
        function updateinternposition(P)
            pixsiz = fn_pixelsize(P.hpanel);
            w = pixsiz(1)/P.nx;
            h = pixsiz(2);
            if h>=12
                % go for a vertical slider
                w1 = min(h*2/3,w/2); %#ok<CPROP>
            else
                % too few vertical space: go for an horizontal slider
                w1 = min(w/2,20); %#ok<CPROP>
            end
            w2 = w-w1;
            for k=1:P.nx
                set(P.hslider(k),'units','pixel','position', [1+(k-1)*w    1-1 w1+1 h+2]) % play a bit with vertical positioning to have a nicer display
                set(P.htext(k),  'units','pixel','position', [1+(k-1)*w+w1 1 w2 h+2])   % idem
            end
        end
    end
    
    % GET/SET - active properties
    methods
        function set.value(P,val)
            if P.doset
                if ~isvector(val) || length(val)~=P.nx
                    error('wrong value length for setting stepper')
                end
                val = min(P.max,max(P.min,val)); %#ok<CPROP,*MCSUP>
                if P.coerce && P.step, val = fn_round(val,P.step); end
                for k=1:P.nx
                    set(P.htext(k),'string',num2str(val(k),P.format))
                end
            end
            P.value = val;
        end
        function set.step(P,step)
            P.step = step;
            if P.doset, P.value = P.value; end
        end
        function set.coerce(P,b)
            P.coerce = b;
            if P.doset, P.value = P.value; end
        end
        function set.min(P,m)
            if ~isscalar(m) && length(m)~=P.nx, error('wrong value for min'), end
            P.min = m;
            if P.doset, P.value = P.value; end
        end
        function set.max(P,M)
            if ~isscalar(M) && length(M)~=P.nx, error('wrong value for max'), end
            P.max = M;
            if P.doset, P.value = P.value; end
        end
        function set.format(P,str)
            P.format = str;
            if P.doset, P.value = P.value; end
        end
    end
    
    % Callbacks
    methods
        function chgvalue(P,k,flag)
            switch flag
                case 'slider'
                    P.value(k) = P.value(k) + P.step*get(P.hslider(k),'value');
                    set(P.hslider(k),'value',0);
                    set(P.htext(k),'string',num2str(P.value(k),P.format));
                case 'text'
                    P.value(k) = str2double(get(P.htext(k),'string')); 
            end
            exec(P)
        end
        function exec(P)
            if isempty(P.callback), return, end
            switch class(P.callback)
                case 'char'
                    evalin('base',P.callback)
                case 'function_handle'
                    feval(P.callback,P,[]);
                case 'cell'
                    feval(P.callback{1},P,[],P.callback{2:end})
            end
        end
    end
    
end

