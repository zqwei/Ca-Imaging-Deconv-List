classdef fn_buttongroup < hgsetget
    % function G = fn_buttongroup(style,str,callback,'prop1',value1,...)
    %---
    % Input:
    % - style       'radio', 'toggle' or 'push'
    % - str         list of string values
    % - callback    function with prototype @(x)fun(x), where x is the
    %               selected string value
    % - propn/valuen    additional properties to be set (possibilities are:
    %                   'parent', 'units', 'position', 'value')
    %
    % No button will be created for an empty string, instead it will be
    % possible  that no button is selected
    
    % Thomas Deneux
    % Copyright 2010-2017   
    
    properties
        callback
        selection
        value
    end
    properties (Dependent)
        unit
        units
        position
    end
    properties (SetAccess='private')
        style       % radio, toggle or push
        vertical    % true or false
        panel
        buttons
        string
        doempty
    end
    properties (Dependent, SetAccess='private')
        parent
    end
    
    % Creation and callback
    methods
        function G = fn_buttongroup(style,str,callback,varargin)
            % Input
            if nargin<1, style = 'radio'; end
            if nargin<2, str = {'a' 'b'}; end
            if nargin<3, callback = ''; end
            G.style = style;
            G.string = cellstr(str);
            idx = find(fn_isemptyc(G.string));
            G.doempty = ~isempty(idx);
            if G.doempty, G.string(idx) = []; end
            G.callback = callback;
            args = reshape(varargin,2,length(varargin)/2);
            iscontrolprop = ismember(args(1,:),{'parent' 'unit' 'units' 'position'});
            
            % create panel
            G.panel = uipanel(args{:,iscontrolprop});
            
            % vertical or horizontal
            sunit = get(G.panel,'unit');
            set(G.panel,'unit','pixel')
            pos = get(G.panel,'pos');
            set(G.panel,'unit',sunit);
            G.vertical = (pos(4)>pos(3)); 
            
            % place buttons
            n = length(G.string);
            G.buttons = zeros(1,n);
            for i = 1:n
                if G.vertical
                    pos = [0 (i-1)/n 1 1/n];
                else
                    pos = [(i-1)/n 0 1/n 1];
                end
                G.buttons(i) = uicontrol('parent',G.panel,'style',[style 'button'], ...
                    'units','normalized','position',pos, ...
                    'string',G.string{i});
                if strcmp(style,'push')
                    % easy
                    set(G.buttons(i),'callback',@(u,e)callback(G.string{i}))
                else
                    % prefer using 'buttondownfcn' rather than 'callback' to
                    % get simultaneous updates of activated and inactivated
                    % options
                    set(G.buttons(i),'enable','inactive', ...
                        'buttondownfcn',@(u,e)changeSelection(G,i,get(u,'value')))
                end
            end
            
            % set additional properties
            if any(~iscontrolprop)
                set(G,args{:,~iscontrolprop})
            end
        end
        function changeSelection(G,i,value)
            if value
                if G.doempty
                    G.selection = [];
                    set(G.buttons(i),'value',0)
                else
                    % do not allow empty selection: do nothing
                    return
                end
            else
                set(G.buttons(G.selection),'value',0)
                G.selection = i;
                set(G.buttons(G.selection),'value',1)
            end
            G.callback(G.value)
        end
    end

    % Get/Set directly on uicontrolgroup
    methods
        function unit = get.unit(G)
            unit = get(G.panel,'unit');
        end
        function set.unit(G,unit)
            set(G.panel,'unit',unit)
        end
        function unit = get.units(G)
            unit = get(G.panel,'unit');
        end
        function set.units(G,unit)
            set(G.panel,'unit',unit)
        end
        function pos = get.position(G)
            pos = get(G.panel,'pos');
        end
        function set.position(G,pos)
            set(G.panel,'pos',pos) %#ok<*MCSUP>
        end
        function h = get.parent(G)
            h = get(G.panel,'parent');
        end
    end
    
    % Get/Set value
    methods
        function val = get.value(G)
            if isempty(G.selection)
                val = '';
            else
                val = get(G.buttons(G.selection),'string');
            end
        end
        function set.value(G,val)
            if isempty(val) && G.doempty
                G.selection = [];
            elseif ischar(val)
                G.selection = find(strcmp(val,G.string));
                if isempty(G.selection), error('incorrect value'), end
            else
                G.selection = val;
            end
            set(G.buttons,'value',0)
            set(G.buttons(G.selection),'Value',1)
        end
    end
    
end