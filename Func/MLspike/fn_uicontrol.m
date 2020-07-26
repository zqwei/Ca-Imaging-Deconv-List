classdef fn_uicontrol < hgsetget
    % embed a control!
    % see also fn_slider, fn_counter, fn_sensor, fn_control
    
    % Thomas Deneux
    % Copyright 2006-2017
    
    properties (Access='protected')
        hu
        hf
    end
    properties (Dependent, SetObservable)
        backgroundcolor
        callback
        foregroundcolor
        horizontalalignment
        max
        min
        position
        string
        style
        units
        value
        buttondownfcn
        deletefcn
        tag
        uicontextmenu
        userdata
        visible
    end
    properties (Dependent, SetAccess='protected')
        parent
    end        
    
    % Constructor
    methods
        function U = fn_uicontrol(varargin)
            % just take the 'parent' argument
            parent = [];
            for i=1:nargin/2
                str = varargin{2*i-1};
                if strcmp(str,'parent')
                    parent = varargin{2*i};
                    break
                end
            end
            if isempty(parent)
                U.hu = uicontrol;
            else
                U.hu = uicontrol('parent',parent);
            end
            U.hf = U.hu;
            while ~strcmp(get(U.hf,'type'),'figure')
                U.hf = get(U.hf,'parent');
            end
            set(U.hu,'deletefcn',@(u,e)delete(U))
        end
        function delete(U)
            if ishandle(U.hu), delete(U.hu), end
        end
    end
    
    % Set/Get
    methods
        function x = get.backgroundcolor(U)
            x = get(U.hu,'backgroundcolor');
        end
        function x = get.callback(U)
            x = get(U.hu,'callback');
        end
        function x = get.foregroundcolor(U)
            x = get(U.hu,'foregroundcolor');
        end
        function x = get.horizontalalignment(U)
            x = get(U.hu,'horizontalalignment');
        end
        function x = get.max(U)
            x = get(U.hu,'max');
        end
        function x = get.min(U)
            x = get(U.hu,'min');
        end
        function x = get.position(U)
            x = get(U.hu,'position');
        end
        function x = get.string(U)
            x = get(U.hu,'string');
        end
        function x = get.style(U)
            x = get(U.hu,'style');
        end
        function x = get.units(U)
            x = get(U.hu,'units');
        end
        function x = get.value(U)
            x = get(U.hu,'value');
        end
        function x = get.buttondownfcn(U)
            x = get(U.hu,'buttondownfcn');
        end
        function x = get.deletefcn(U)
            x = get(U.hu,'deletefcn');
        end
        function x = get.tag(U)
            x = get(U.hu,'tag');
        end
        function x = get.uicontextmenu(U)
            x = get(U.hu,'uicontextmenu');
        end
        function x = get.userdata(U)
            x = get(U.hu,'userdata');
        end
        function x = get.visible(U)
            x = get(U.hu,'visible');
        end
            
        function set.backgroundcolor(U,x)
            set(U.hu,'backgroundcolor',x);
        end
        function set.callback(U,x)
            set(U.hu,'callback',x);
        end
        function set.foregroundcolor(U,x)
            set(U.hu,'foregroundcolor',x);
        end
        function set.horizontalalignment(U,x)
            set(U.hu,'horizontalalignment',x);
        end
        function set.max(U,x)
            set(U.hu,'max',x);
        end
        function set.min(U,x)
            set(U.hu,'min',x);
        end
        function set.position(U,x)
            set(U.hu,'position',x);
        end
        function set.string(U,x)
            set(U.hu,'string',x);
        end
        function set.style(U,x)
            set(U.hu,'style',x);
        end
        function set.units(U,x)
            set(U.hu,'units',x);
        end
        function set.value(U,x)
            set(U.hu,'value',x);
        end
        function set.buttondownfcn(U,x)
            set(U.hu,'buttondownfcn',x);
        end
        function set.deletefcn(U,x)
            set(U.hu,'deletefcn',x);
        end
        function set.tag(U,x)
            set(U.hu,'tag',x);
        end
        function set.uicontextmenu(U,x)
            set(U.hu,'uicontextmenu',x);
        end
        function set.userdata(U,x)
            set(U.hu,'userdata',x);
        end
        function set.visible(U,x)
            set(U.hu,'visible',x);
        end
        
        function x = get.parent(U)
            x = get(U.hu,'parent');
        end
        function set.parent(U,x)
            % just ignore
        end
    end
    
    % Routines
    methods
        function execcallback(U)
            if isempty(U.callback), return, end
            switch class(U.callback)
                case 'char'
                    evalin('base',U.callback)
                case 'function_handle'
                    feval(U.callback,U,[]);
                case 'cell'
                    feval(U.callback{1},U,[],U.callback{2:end})
            end
        end
    end
    
end
