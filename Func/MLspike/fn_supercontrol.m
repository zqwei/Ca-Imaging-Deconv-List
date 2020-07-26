classdef fn_supercontrol < hgsetget
    % function X = fn_supercontrol([hp,]specs[,callback[,x0]])
    % function specs = fn_supercontrol.examplespecs
    % function fn_supercontrol('demo')
    %---
    % Input:
    % - hp          uipanel handle
    % - specs       structure with fields:
    %               . name      string
    %               . controls  structure with fields (* is mandatory):
    %                           style*  popupmenu, edit, checkbox,
    %                                   radiobutton, togglebutton,
    %                                   pushbutton, stepper, file or dir 
    %                           string  the 'string' property of the
    %                                   control
    %                           length* relative width occupied by the
    %                                   control + its label if any
    %                           default* default value (type depends on
    %                                   control style)
    %                           label   a label placed on the left
    %                           labellength     relative width occupied by
    %                                   the label (set to 0 if no label)
    %                           callback        for push button only:
    %                                   - function with prototype 
    %                                   valuek = fun(value) where value is
    %                                   a cell array and valuek an element
    %                                   of this array [MORE DOC NEEDED]
    %                                   - or character array: flag that
    %                                   will be sent to X.callback
    %                           type    type of the value (useful in
    %                                   particular for the 'edit' style)
    %                           more    more properties stored in a cell
    %                                   array with successive pairs of
    %                                   property names/values
    % - callback    function to be executed when control values are
    %               changed by user, with prototype @(x)fun(x),
    %               where x is X.x (see below)
    % - x0          initial value (see below comments on X.x)
    %
    % Output:
    % - X           fn_supercontrol object; X.x is a structure that
    %               stores the values, with fields:
    %               .name       string
    %               .active     logical
    %               .value      cell array with values (one per
    %                           control in the specs of the same
    %                           name)
    %
    % One can change the values either by user action (acionning
    % the controls) or by setting the value of X.x.
    %
    % Special notes:
    % - chgactive flag: The callback might be invoked but the
    % "active" part of the value has not changed (for example, when
    % a new, inactive line has been creadted). The property
    % X.activechg says whether this active part has changed or not.
    % - 'edit': if the type is set to 'char' or not set, non-character
    % values are stored in the 'userdata' property and the string
    % 'userdata' appears; the same happens when the type is numeric or
    % logical and values are too large to be displayed correctly
    % - 'pushbutton': when pressing the button, the callback is executed
    % and changes the value accordingly
    %
    % See also fn_control
 
    % Thomas Deneux
    % Copyright 2010-2017
   
    % Content
    properties
        hp
        hpsub
        slider
        x_data = struct('name',{},'active',{},'value',{});
        callback
        specs
        activechg = false;  % change in the active part?
    end
    properties (Dependent)
        x
        immediateupdate
    end
    properties (Dependent, SetAccess='private')
        nx
    end
    % Private 
    properties
        controls = struct( ...
            'panel',{}, ...
            'check',{}, ...
            'contentpanel',{},'content',{}, ...
            'move',{},'close',{});
        addlinecontrol
        immupdcontrol
        ncharname
    end
   
    % Constructor
    methods
        function X = fn_supercontrol(varargin) 
            % function X = fn_supercontrol([hp,]specs[,callback[,x0]])
            % input
            if isstruct(varargin{1})
                hp = gcf;
            elseif ischar(varargin{1}) && strcmp(varargin{1},'demo')
                hp = figure;
                varargin = {fn_supercontrol.examplespecs,@disp};
            else
                hp = varargin{1}; varargin(1) = [];
            end
            specs = varargin{1};
            if length(varargin)<2, callback = []; else callback = varargin{2}; end
            if length(varargin)<3, x0 = []; else x0 = varargin{3}; end
            
            % some default values inside the panel
            set(hp,'defaultuicontrolfontsize',8)
            delete(get(hp,'children'))
            
            % maximum number of character for the names: allow 20% of names
            % to be not displayed completely 
            namelengths = fn_map(@length,{specs.name}); 
            %             X.ncharname = prctile(namelengths,80); %
            % the same, but without using the Statistics toolbox
            namelengths = sort(namelengths);
            X.ncharname = namelengths(ceil(length(namelengths)*.8));
            
            % set properties
            X.hp = hp;
            X.callback = callback;
            X.specs = specs;
            
            % default background color
            colprop = fn_switch(get(hp,'type'),'figure','color','uipanel','backgroundcolor');
            defaultcolor = get(hp,colprop);
            if strcmp(get(hp,'type'),'figure'), set(hp,'defaultuipanelbackgroundcolor',defaultcolor), end
            set(hp,'defaultuicontrolbackgroundcolor',defaultcolor)
            
            % 'add line' control and subpanel for lines
            display_init(X)
            
            % default value (automatic display)
            if ~isempty(x0), X.x = x0; end
        end
    end
    
    % Give an example specification
    methods (Static)
        function specs = examplespecs()
            specs = struct( ...
                'name',     'myname', ...
                'controls', struct('style','edit','string','','length',2,'default',{'hip' 'hop' 3},'label',{'firstname' 'lastname' 'age'},'labellength',1,'type',{[] [] 'double'},'more',{{'backgroundcolor','y','fontweight','bold'}}) ...
                );
        end
    end
    
    % Get/Set
    methods
        function x = get.x(X)
            x = X.x_data;
        end
        function set.x(X,x)
            oldx = X.x_data;
            if isequal(oldx,x), return, end
            if isempty(x), x = struct('name',{},'active',{},'value',{}); end % just to make sure
            X.x_data = x;
            if length(x)>=length(oldx) && isequal({x.name},{oldx.name})
                % change line contents only
                for i=1:length(oldx), display_contentvalue(X,i), end
                for i=length(oldx)+1:length(x), display_line(X,i), end
            else
                % re-display everything
                display_clear(X)
                for i=1:length(x), display_line(X,i), end
            end
            display_updateslider(X)
        end
        function nx = get.nx(X)
            nx = length(X.x_data);
        end
        function b = get.immediateupdate(X)
            b = logical(get(X.immupdcontrol,'value'));
        end
        function set.immediateupdate(X,b)
            set(X.immupdcontrol,'value',b)
            if b, evalfun(X), end
        end
    end
    
    % Display
    % (all these functions update X.controls and the display; X.x is
    % supposed to be already set to the new value)
    methods
        function [W H h hdec hbut hdectext htext wslider] = display_sizes(X)
            tmp = fn_pixelsize(X.hp);
            W = tmp(1); H = tmp(2);
            h = 25;
            hdec = 5;
            hbut = h-8;
            hdectext = (h-10)/2+1; 
            htext = 10;
            wslider = 12;
        end
        function display_init(X)
            [W H h hdec hbut hdectext htext wslider] = display_sizes(X);  %#ok<ASGLU>
            X.addlinecontrol = uicontrol('parent',X.hp,'style','popupmenu', ...
                'units','pixel','position',[10 H-h+hdec 100 hbut], ...
                'string',{'add line...' X.specs.name}, ...
                'callback',@(u,e)data_addline(X));
            if isscalar(X.specs), set(X.addlinecontrol,'style','pushbutton','string','add line'), end
            uicontrol('parent',X.hp,'style','pushbutton', ...
                'units','pixel','position',[120 H-h+hdec 45 hbut], ...
                'string','Update', ...
                'callback',@(u,e)evalfun(X,true));
            X.immupdcontrol = uicontrol('parent',X.hp,'style','radiobutton', ...
                'units','pixel','position',[170 H-h+hdec 80 hbut], ...
                'string','immediate', ...
                'value',true, ...
                'callback',@(u,e)evalfun(X));
            X.hpsub = uipanel('parent',X.hp, ...
                'borderwidth',0, ...
                'units','pixel','pos',[1 1 W-wslider-2 H-h]);
            X.slider = fn_slider('parent',X.hp, ...
                'units','pixel','position',[W-wslider 1 wslider-3 H-h], ...
                'layout','down', ...
                'mode','point','max',0, ...
                'callback',@(u,e)display_linepositions(X));
        end
        function display_line(X,i)
            [W H h hdec hbut hdectext htext wslider] = display_sizes(X); %#ok<ASGLU>
            W = W-wslider-5; 
            H = H-h; %#ok<NASGU>
            hpi = uipanel('parent',X.hpsub, ...
                'units','pixel','borderwidth',0, ...
                'userdata',i);
            X.controls(i).panel = hpi;
            display_linepositions(X,i)
            wcheck = 20+7*X.ncharname;
            wplusminus = 2+2*hbut;
            wcontent = W-wcheck-wplusminus;
            kspec = strcmpi(X.x(i).name,{X.specs.name});
            X.controls(i).check = uicontrol('parent',hpi,'style','checkbox', ...
                'units','pixel','position',[1 hdec wcheck hbut], ...
                'string',X.specs(kspec).name, ...
                'value',X.x(i).active, ...
                'callback',@(u,e)data_toggleactive(X,u));
            X.controls(i).contentpanel = uipanel('parent',hpi, ...
                'units','pixel','position',[wcheck+1 1 wcontent h], ...
                'borderwidth',0);
            X.controls(i).move = uicontrol('parent',hpi,'style','slider', ...
                'units','pixel','position',[W-wplusminus+2 hdec hbut-1 hbut], ...
                'min',-1,'max',1,'sliderstep',[1 1],'value',0, ...
                'callback',@(u,e)data_move(X,u));
            X.controls(i).close = uicontrol('parent',hpi,'style','pushbutton', ...
                'units','pixel','position',[W-wplusminus+1+hbut hdec hbut hbut], ...
                'string','X', ...
                'callback',@(u,e)data_remove(X,u));
            display_linecontent(X,i)
        end
        function display_linepositions(X,klines)
            if nargin<2, klines = 1:length(X.controls); end
            [W H h] = display_sizes(X);
            H = H-h;
            sliderval = X.slider.value;
            for i=klines
                posi = [1 H+(sliderval-i)*h W h];
                set(X.controls(i).panel,'position',posi, ...
                    'visible',fn_switch(posi(2)>0 && posi(2)+posi(4)<=H))
            end
        end
        function display_linecontent(X,i)
            % locate the corresponding content and panel
            name = X.x(i).name;
            kspec = find(strcmpi(name,{X.specs.name}));
            if ~isscalar(kspec), error('invalid name'), end
            spec = X.specs(kspec).controls;
            ncontrol = length(spec);
            totallength = sum([spec.length]);
            contentpanel = X.controls(i).contentpanel;
            content = cell(1,ncontrol);
            % sizes
            [W H h hdec hbut hdectext htext] = display_sizes(X); %#ok<ASGLU>
            pos = get(contentpanel,'position');
            WP = pos(3); 
            wdec = 2;
            wunit = (WP-(ncontrol+1)*wdec)/totallength;
            % display controls
            xpos = wdec+1;
            for k=1:ncontrol
                speck = spec(k);
                if isfield(speck,'label') && ~isempty(speck.label)
                    w = speck.labellength*wunit-1;
                    uicontrol('parent',contentpanel,'style','text', ...
                        'units','pixel','position',[xpos hdectext w htext], ...
                        'string',speck.label);
                    xpos = xpos + w + 1;
                    w = (speck.length-speck.labellength)*wunit;
                else
                    w = speck.length*wunit;
                end
                switch speck.style
                    case {'popupmenu' 'edit' 'pushbutton' 'checkbox' 'togglebutton' 'radiobutton'}
                        content{k} = uicontrol('parent',contentpanel, ...
                            'style',speck.style);
                        if isfield(speck,'string'), set(content{k},'string',speck.string); end
                    case {'file' 'dir'}
                        content{k} = uicontrol('parent',contentpanel, ...
                            'style','edit', ...
                            'backgroundcolor',[.8 .8 .8], ...
                            'enable','inactive', ...
                            'buttondownfcn',@(u,e)chgfilevalue(X,u,k,speck.style));
                        if isfield(speck,'string'), set(content{k},'string',speck.string); end
                    case 'stepper'
                        content{k} = fn_stepper('parent',contentpanel);
                    otherwise
                        error('style ''%s'' is not handled yet',speck.style)
                end
                set(content{k}, ...
                    'units','pixel','position',[xpos hdec w hbut], ...
                    'callback',@(u,e)data_userset(X,u,k));
                if isfield(speck,'more') && ~isempty(speck.more), set(content{k},speck.more{:}), end
                xpos = xpos + w + wdec;
            end
            X.controls(i).content = content;
            display_contentvalue(X,i)
        end
        function chgfilevalue(X,u,k,mode)
            fname = fn_getfile(fn_switch(mode,'file','SAVE','dir','DIR'));
            set(u,'string',fname)
            data_userset(X,u,k)
        end
        function display_contentvalue(X,i)
            % active value
            set(X.controls(i).check,'value',X.x(i).active)
            % content values
            name = X.x(i).name;
            kspec = find(strcmpi(name,{X.specs.name}));
            if ~isscalar(kspec), error('invalid name'), end
            spec = X.specs(kspec).controls;
            ncontrol = length(spec);
            content = X.controls(i).content;
            for k=1:ncontrol
                speck = spec(k);
                if length(X.x(i).value)<k
                    disp 'problem in fn_supercontrol'
                    val = spec(k).default;
                else
                    val = X.x(i).value{k};
                end
                switch speck.style
                    case 'popupmenu'
                        klist = find(strcmp(val,speck.string));
                        if ~isscalar(klist), error('value is not in list'), end
                        set(content{k},'value',klist)
                    case 'edit'
                        if isfield(speck,'type'), type = speck.type; else type = 'char'; end
                        if ischar(val)
                            if ~strcmp(type,'char'), error 'value is expected to be numeric', end
                            set(content{k},'string',val)
                        elseif isnumeric(val) || islogical(val)
                            okdisp = false;
                            if ~strcmp(type,'char')
                                [str errormsg] = fn_chardisplay(val);
                                okdisp = isempty(errormsg);
                            end
                            if okdisp
                                set(content{k},'string',str)
                            else
                                set(content{k},'string','userdata','userdata',val)
                            end
                        else
                            error('incorrect value type for edit control')
                        end
                    case {'file' 'dir'}
                        set(content{k},'string',val)
                    case {'checkbox' 'togglebutton' 'radiobutton'}
                        set(content{k},'value',val)
                    case 'pushbutton'
                        %set(content{k},'userdata',val);
                    case 'stepper'
                        set(content{k},'value',val)
                    otherwise
                        error('this control style is not handled yet')
                end
            end
        end
        function display_clear(X,ind)
            if nargin<2, ind = 1:length(X.controls); end
            for i = ind
                try delete(X.controls(i).panel), end
                X.controls(i).panel = [];
            end
        end
        function display_moveline(X,i,j,doswitch)
            if doswitch
                X.controls([j i]) = X.controls([i j]);
                display_linepositions(X,[i j]);
                set(X.controls(i).panel,'userdata',i)
                set(X.controls(j).panel,'userdata',j)
            else
                X.controls(j) = X.controls(i);
                display_linepositions(X,j)
                set(X.controls(j).panel,'userdata',j)
            end
        end
        function display_updateslider(X)
            [W H h] = display_sizes(X); %#ok<ASGLU>
            H = H-h; % height of the subpanel
            nmax = floor(H/h);
            X.slider.max = max(0,X.nx-nmax);
            X.slider.width = min(nmax/X.nx,1);
        end
    end
    
    % Data
    methods
        function data_userset(X,u,k)
            % function data_userset(X,u,k)
            %---
            % u is the control whose value has been changed by user
            % k is the index of the control in the set of controls 
            i = get(get(get(u,'parent'),'parent'),'userdata'); % index in X.x being modified
            % locate the corresponding content and panel
            name = X.x(i).name;
            kspec = strcmpi(name,{X.specs.name});
            speck = X.specs(kspec).controls(k);
            switch speck.style
                case 'pushbutton'
                    fun = speck.callback;
                    if isempty(fun)
                        disp 'no action for push button'
                        return
                    elseif ischar(fun)
                        feval(X.callback,fun)
                    else
                        vali = X.x_data(i).value;
                        val = feval(fun,vali);
                        if isempty(val), return, end
                    end
                case 'popupmenu'
                    str = speck.string;
                    val = str{get(u,'value')};
                case {'edit' 'file' 'dir'}
                    str = get(u,'string');
                    if strcmp(str,'userdata')
                        errordlg('you cannot set the value to ''userdata'' as this is a special flag');
                        return
                    elseif ~isfield(speck,'type')
                        val = str;
                    else
                        [val errormsg] = fn_chardisplay(str,speck.type);
                        if ~isempty(errormsg)
                            % error -> re-display the previous value
                            display_contentvalue(X,i)
                            return
                        end
                    end
                case {'checkbox' 'togglebutton' 'radiobutton'}
                    val = logical(get(u,'value'));
                case 'stepper'
                    val = get(u,'value');
                otherwise
                    error('this control style is not handled yet')
            end
            X.x_data(i).value{k} = val;
            % eval fn_supercontrol callback
            X.activechg = X.x(i).active;
            evalfun(X)
        end
        function data_toggleactive(X,u)
            i = get(get(u,'parent'),'userdata');
            X.x_data(i).active = logical(get(u,'value'));
            % eval fn_supercontrol callback
            X.activechg = true;
            evalfun(X)
        end
        function data_addline(X)
            k = fn_switch(isscalar(X.specs),1,get(X.addlinecontrol,'value')-1);
            set(X.addlinecontrol,'value',1)
            if k==0, return, end
            i = X.nx+1;
            % update data
            X.x_data(i) = struct( ...
                'name',lower(X.specs(k).name), ...
                'active',false, ...
                'value',{{X.specs(k).controls.default}});
            % update slider
            display_updateslider(X)
            % display line
            display_line(X,i)
            % eval fn_supercontrol callback
            X.activechg = false;
            evalfun(X)
        end
        function data_move(X,u)
            i = get(get(u,'parent'),'userdata');
            j = i-get(u,'value');
            set(u,'value',0)
            if j<1 || j>X.nx, return, end
            X.x_data([i j]) = X.x_data([j i]);
            display_moveline(X,i,j,true)
            % eval fn_supercontrol callback
            X.activechg = X.x(i).active & X.x(j).active;
            evalfun(X)
        end
        function data_remove(X,u)
            i = get(get(u,'parent'),'userdata');
            X.activechg = X.x(i).active;
            X.x_data(i) = [];
            % update slider
            display_updateslider(X)
            % update lines
            display_clear(X,i)
            for j=i:X.nx
                display_moveline(X,j+1,j,false)
            end
            % eval fn_supercontrol callback
            evalfun(X)
        end
    end
    
    % Callback
    methods
        function evalfun(X,force)
            if nargin<2, force = false; end
            if X.immediateupdate || force 
                if ~isempty(X.callback), feval(X.callback,X.x), end
            end
        end
    end
    
    % Check-up
    methods (Static)
        function [b msg] = checkup(x,specs)
            % check whether structure x meets specifications specs
            b = false;
            if ~isempty(setxor(fieldnames(x),{'name' 'active' 'value'})), msg = 'structure does not correct fields]'; return, end
            if ~all(ismember(upper({x.name}),upper({specs.name}))), msg = 'some entries are unknown'; return, end
            if ~all(ismember([x.active],[false true])), msg = '''active'' fields are not logical values'; return, end
            for i=1:length(x)
                namei = x(i).name;
                vali = x(i).value;
                speci = specs(strcmpi(namei,{specs.name})).controls;
                if length(vali)~=length(speci), msg = ['''' namei ''' entry does not have the correct number of values']; return, end
                for k=1:length(vali)
                    valk = vali{k};
                    speck = speci(k);
                    switch speck.style
                    case 'popupmenu'
                        if ~ischar(valk), msg = ['''' namei ''' entry is not a char']; return, end
                        if ~ismember(valk,speck.string)
                            msg = ['''' namei ''' entry, ''' valk ''', is not in specification list'];
                            return
                        end
                    case 'edit'
                    case {'file' 'dir'}
                        if ~ischar(valk), msg = ['''' namei ''' entry is not a valid path string']; return, end
                    case {'checkbox' 'togglebutton' 'radiobutton'}
                        if ~isscalar(valk) || (~islogical(valk) && ~(isnumeric(valk) && ismember(valk,[0 1])))
                            msg = ['''' namei ''' entry is not a valid logical value'];
                            return
                        end
                    case 'pushbutton'
                    case 'stepper'
                        if ~isnumeric(valk) || ~isscalar(valk)
                            msg = ['''' namei ''' entry is not a scalar numerical value'];
                        end
                    otherwise
                        error('this control style is not handled yet')
                    end
                end
            end
            b = true;
            msg = '';
        end
    end
    
end