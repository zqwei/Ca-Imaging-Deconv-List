classdef fn_multcheck < hgsetget
    % function fn_multcheck([n,][properties])
    % function fn_multcheck({'name1','name2',...},[properties])
    %---
    % custom uicontrol (row of check boxes)
    
    % Thomas Deneux
    % Copyright 2009-2017
    properties
        nx
        value
        callback
        deletefcn
    end
    properties (Dependent)
        units
        position
        foregroundcolor
        backgroundcolor
        visible
    end
    properties (Access='private')
        parent
        hpanel          % uipanel
        hu
        doset = false;
    end
    
    % Constructor/Destructor
    methods
        function P = fn_multcheck(varargin)
            % Number of steppers
            if mod(nargin,2)
                a = varargin{1};
                if iscell(a)
                    P.nx = length(a);
                    names = a;
                else
                    P.nx = a;
                    names = cell(1,P.nx);
                end
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
            P.value = false(1,P.nx);
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
            % sliders and text fields - for the moment, use only normalized
            % positionning
            P.hu = zeros(1,P.nx);
            w = 1/P.nx;
            for k=1:P.nx
                P.hu(k) = uicontrol('parent',P.hpanel,'style','checkbox', ...
                    'string',names{k}, ...
                    'units', 'normalized', 'position', [(k-1)*w 0 w 1], ...
                    'value', 0, ...
                    'callback', @(u,e)chgvalue(P,k));
            end
            
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
            set([P.hpanel P.hu],'foregroundcolor',c);
        end
        function c = get.backgroundcolor(P)
            c = get(P.hpanel,'backgroundcolor');
        end
        function set.backgroundcolor(P,c)
            set([P.hframe P.hslider P.htext],'backgroundcolor',c);
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
    end
    
    % GET/SET - active properties
    methods
        function set.value(P,val)
            if P.doset %#ok<*MCSUP>
                if ~isvector(val) || length(val)~=P.nx
                    error('wrong value length for setting stepper')
                end
                for k=1:P.nx
                    set(P.hu(k),'value',val(k))
                end
            end
            P.value = logical(val);
        end
    end
    
    % Callbacks
    methods
        function chgvalue(P,k)
            P.value(k) = get(P.hu(k),'value');
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

