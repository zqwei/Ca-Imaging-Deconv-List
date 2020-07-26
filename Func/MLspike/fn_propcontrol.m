classdef fn_propcontrol < hgsetget
% function fn_propcontrol(obj,prop,spec,graphic object options...)
% function fn_propcontrol(obj,prop,spec,{graphic object options...})
% function hu = fn_propcontrol.createcontrol(...)
%---
% Create a control that will be synchronized to an object property value.
% Use the static method fn_propcontrol.createcontrol (3rd syntax above) to
% return the graphic handle of the control rather than the fn_propcontrol
% object.
% 
% Input:
% - obj     the object whose property is observed
% - prop    the name of the observed property THIS PROPERTY MUST BE SET AS 
%           OBSERVABLE, AND ITS SET ACCESS MUST BE PUBLIC
% - spec    specification of both the value type and the control style:
%           . for logical values: 'checkbox', 'radiobutton' or 'menu'
%           . for numerical and char values: 'char', 'double', 'uint8', etc
%           . for list of values: {spec value1 value2 ...}
%             or {spec {values...} {labels...} [{shortlabels...}]} where
%             spec is any of 'listbox', 'checkbox', 'pushbutton', 'menu'
%             (one entry with sub-entries), 'menuval' (same, and value is
%             indicated on the top-level entry), 'menugroup' (multiple
%             entries at the first level) Under these two options, two
%             special behaviors are available:
%             * if 'labels' has one value less than 'values', the last
%               element of 'values' is considered as a default value that
%               is set when unchecking the current value (such value would
%               typically be '', [] or 0).
%             * if on the contrary 'labels' has one more value than
%               'values' (typically, 'others...'), this label is checked
%               whenever the property value is not in the list, and when
%               this label is pressed, a small input window lets the user
%               select the desired value
% - options options for the graphic object that will be created
%           - If spec is 'menu', 'menuval' or 'menugroup', it is mandatory
%           that options will contain the pair ('parent',parentmenu).
%           - Options chain can start with handle of parent without the
%           preceding 'parent' key.
%           - Labels should be set with property 'string' for 'checkbox',
%           'char', 'double', etc., and with property 'label' for
%           'menu', etc. If not specified, the name of the observed
%           property is used.
%           For better readability, options can be nested inside a cell
%           array.
%
% See also: fn_menugroup, fn_control, fn_setpropertyandmark

% Thomas Deneux
% Copyright 2015-2017

properties (SetAccess='private')
    % controled object
    obj
    prop
    % control object(s)
    hu
    hparent             % 'sub' menu style only: entry at top level
    % control specification
    type
    style
    valuelist
    labellist
    % additional specifications for menu
    doautolabel = false % 'sub' menu style only: display value in the label of top level parent?  
    toplabel            % used when 'doautolabel' is true
    shortlabels         % used when 'doautolabel' is true
    dodefaultvalue = false
    defaultvalue
    doother = false
    docolor = false
    % property listener
    proplistener
end
properties
    enabled = true
    visible = true
end

% Constructor, destructor
methods
    function M = fn_propcontrol(obj,prop,spec,varargin)
        M.obj = obj;
        M.prop = prop;
        if isscalar(varargin) && iscell(varargin{1})
            varargin = varargin{1};
        end
            
        
        % if several objects, only the first one will be watched
        obj = obj(1);
        
        % list of values
        M.labellist = []; M.shortlabels = [];
        if iscell(spec)
            if length(spec)==1
                error 'missing list of values'
            elseif iscell(spec{2})
                M.valuelist = spec{2};
                if length(spec)>=3
                    M.labellist = spec{3}; 
                    if length(M.labellist)==length(M.valuelist)-1
                        M.dodefaultvalue = true;
                        M.defaultvalue = M.valuelist{end};
                        M.valuelist(end) = [];
                    elseif length(M.labellist)==length(M.valuelist)+1
                        M.doother = true;
                    elseif length(M.labellist)~=length(M.valuelist)
                        error 'number of labels must be equal to or one less than number of values'
                    end
                end
                if length(spec)>=4
                    M.shortlabels = spec{4};
                    if ~iscell(M.shortlabels) || length(M.shortlabels)~=length(M.labellist)-M.doother
                        error 'number of short labels does not match number of labels'
                    end
                end
            else
                M.valuelist = spec(2:end);
            end
            spec = spec{1};
            if M.dodefaultvalue && ~ismember(spec,{'menu' 'menuval' 'menugroup'})
                error 'default value is possible only for ''menu'', ''menuval'' or ''menugroup'' options, otherwise the number of labels must be equal to the number of values'
            end
        elseif ischar(spec) && ismember(spec,{'listbox' 'popupmenu'})
            kstring = strcmpi(varargin(1:2:end),'string');
            if isempty(kstring), error 'missing list of values', end
            M.valuelist = cellstr(varargin{kstring});
        end
        
        % special: color
        M.docolor = false;
        if ~isempty(regexpi(prop,'color')) && ~isempty(M.valuelist) && any(fn_map(@ischar,M.valuelist))
            % try converting color names to colors
            try
                [colornum colorname] = deal(cell(1,length(M.valuelist)));
                for i=1:length(colornum)
                    [colornum{i} colorname{i}] = fn_colorbyname(M.valuelist{i},'strict');
                end
                M.valuelist = colornum;
                if isempty(M.labellist), M.labellist = repmat({'X'},1,length(colornum)); end
                if isempty(M.shortlabels), M.shortlabels = colorname; end
                M.docolor = true;
            catch
                set(0,'defaultlinecolor',deflinecolor)
            end
        end
        if ~isempty(M.valuelist)
            if isempty(M.labellist), M.labellist = fn_num2str(M.valuelist); end
            if isempty(M.shortlabels), M.shortlabels = M.labellist; end
        end
        
        % set type and style
        switch spec
            case {'checkbox' 'radiobutton'}
                M.type = 'logical';
                M.style = spec;
            case {'char' 'double' 'single' 'uint8' 'uint16' 'uint32' 'uint64' 'int8' 'int16' 'int32' 'int64'}
                M.type = spec;
                M.style = 'edit';
            case {'listbox' 'popupmenu' 'pushbutton'}
                M.type = 'list';
                M.style = spec;
            case {'menuval' 'menugroup'}
                M.type = 'list';
                M.style = 'menugroup';
                menustyle = fn_switch(spec,'menuval','sub+val','menugroup','group');
            case 'menu'
                if ~iscell(M.valuelist)
                    M.type = 'logical';
                    M.style = 'menu';
                else
                    M.type = 'list';
                    M.style = 'menugroup';
                    menustyle = 'sub';
                end
            otherwise
                error('unknown specification ''%s''',spec)
        end
        if strcmp(M.type,'logical') && ischar(get(M.obj,M.prop))
            M.type = 'on/off';
        end
        
        % create control(s)
        if mod(length(varargin),2), varargin = ['parent' varargin]; end
        switch M.style
            case 'menu'
                M.hu = uimenu('label',M.prop,varargin{:});
            case 'menugroup'
                switch menustyle
                    case 'group'
                        kparent = find(strcmpi(varargin(1:2:end),'parent'));
                        mparent = varargin{2*kparent};
                        varargin(2*(kparent-1)+(1:2)) = [];
                    case {'sub' 'sub+val'}
                        M.doautolabel = strcmp(menustyle,'sub+val');
                        mparent = uimenu('label',M.prop,varargin{:},'deletefcn',@(u,e)delete(M));
                        M.hparent = mparent;
                        % if label is not set, label will be automatically
                        % updated to display current value
                        if M.doautolabel
                            klab = find(strcmpi(varargin(1:2:end),'label'));
                            if isempty(klab)
                                M.toplabel = M.prop;
                            else
                                M.toplabel = varargin{2*klab};
                            end
                        end
                        varargin = {};
                end
                n = length(M.valuelist);
                M.hu = gobjects(1,n+M.doother);
                dosep = ~isempty(get(mparent,'children'));
                for i=1:n
                    M.hu(i) = uimenu(mparent,'label',M.labellist{i});
                    if M.docolor, set(M.hu(i),'foregroundcolor',colornum{i}), end
                    if i==1 && dosep, set(M.hu(i),'separator','on'), end
                    if ~isempty(varargin), set(M.hu(i),varargin{:}); end
                end
                if M.doother
                    M.hu(n+1) = uimenu(mparent,'label',M.labellist{i+1});
                end
            case {'listbox' 'popupmenu'}
                M.hu = uicontrol('style',M.style,'string',M.labellist,varargin{:});
            case 'pushbutton'
                M.hu = uicontrol('style',M.style,varargin{:});
            otherwise
                M.hu = uicontrol('style',M.style,'string',M.prop,varargin{:});
        end
        
        % set callback
        switch M.style
            case 'menugroup'
                for i=1:n+M.doother
                    set(M.hu(i),'callback',@(u,e)setvalue(M,i))
                end
            otherwise
                set(M.hu,'callback',@(u,e)setvalue(M))
        end
        
        % display value
        updatevalue(M)
        
        % watch object property
        M.proplistener = addlistener(obj,prop,'PostSet',@(u,e)updatevalue(M));
        
        % delete everything upon object deletion or control deletion
        fn_deletefcn(obj,@(u,e)delete(M))
        set(M.hu,'deletefcn',@(u,e)delete(M))
    end
    function delete(M)
        if ~isprop(M,'proplistener'), return, end
        deleteValid(M.proplistener,M.hu,M.hparent)
    end
end

% Bi-direction updates (object->control, control->object)
methods
    function updatevalue(M)
        curval = get(M.obj(1),M.prop);
        if strcmp(M.type,'on/off'), curval = fn_switch(curval,'logical'); end
        if M.docolor
            % try to convert color to nice string representation
            [colornum colorname] = fn_colorbyname(curval);
            if ~isempty(colornum), curval = colornum; end
        end
        switch M.style
            % type logical or on/off
            case 'menu'
                set(M.hu,'checked',fn_switch(curval))
            case {'checkbox' 'radiobutton'}
                set(M.hu,'value',curval)
            % edit
            case 'char'
                set(M.hu,'string',curval)
            case 'edit'
                set(M.hu,'string',fn_chardisplay(curval))
            % list of values
            case 'menugroup'
                set(M.hu,'checked','off')
                if M.docolor
                    idx = fn_find(curval,M.valuelist); % color values are stored as numerical values
                else
                    idx = fn_find(curval,M.valuelist);
                end
                set(M.hu(idx),'checked','on')
                if isempty(idx) && M.doother
                    set(M.hu(end),'checked','on')
                end
                if M.doautolabel
                    if ~isempty(idx)
                        valstr = M.shortlabels{idx};
                    elseif M.docolor && ~isempty(colorname)
                        valstr = colorname;
                    else
                        valstr = fn_num2str(curval);
                    end
                    if isempty(valstr), valstr = '(none)'; end
                    set(M.hparent,'label',[M.toplabel ': ' valstr])
                end
            case {'listbox' 'popupmenu'}
                n = length(M.valuelist);
                check = false(1,n);
                if get(M.hu,'max')-get(M.hu,'min')<=1
                    curval = {curval};
                end
                for i=1:length(curval)
                    for j=1:n
                        if isequal(curval{i},M.valuelist{j})
                            check(j) = true;
                            break;
                        end
                    end
                end
                set(M.hu,'value',find(check))
            case 'pushbutton'
                idx = fn_find(curval,M.valuelist);
                set(M.hu,'string',M.labellist{idx},'userdata',idx)
            otherwise
                error('style ''%s'' not handled in method ''updatevalue''',M.style)
        end
    end
    function setvalue(M,i)
        switch M.style
            % type logical or on/off
            case 'menu'
                if strcmp(M.type,'on/off')
                    set(M.obj,M.prop,fn_switch(get(M.hu,'checked'),'toggle'));
                else
                    set(M.obj,M.prop,~fn_switch(get(M.hu,'checked'),'logical'));
                end
            case {'checkbox' 'radiobutton'}
                if strcmp(M.type,'on/off')
                    set(M.obj,M.prop,fn_switch(get(M.hu,'checked'),'on/off'));
                else
                    set(M.obj,M.prop,logical(get(M.hu,'value')));
                end
            % edit
            case 'edit'
                if strcmp(M.type,'char')
                    set(M.obj,M.prop,get(M.hu,'string'));
                else
                    set(M.obj,M.prop,fn_chardisplay(get(M.hu,'value'),M.type));
                end
            % list of values
            case 'menugroup'
                if (i==0 || strcmp(get(M.hu(i),'checked'),'on')) && M.dodefaultvalue
                    set(M.obj,M.prop,M.defaultvalue);
                elseif i>length(M.valuelist) && M.doother
                    value = fn_input(['enter ' M.prop ' value:'],get(M.obj,M.prop));
                    if isempty(value), return, end % input window was closed
                    set(M.obj,M.prop,value)
                else
                    set(M.obj,M.prop,M.valuelist{i});
                end
            case {'listbox' 'popupmenu'}
                idx = get(M.hu,'value');
                if get(M.hu,'max')-get(M.hu,'min')>1
                    set(M.obj,M.prop,M.valuelist(idx));
                else
                    set(M.obj,M.prop,M.valuelist{idx});
                end
            case 'pushbutton'
                n = length(M.valuelist);
                idx = 1+mod(get(M.hu,'userdata'),n);
                set(M.hu,'userdata',idx,'string',M.labellist{idx})
                set(M.obj,M.prop,M.valuelist{idx})
            otherwise
                error('style ''%s'' not handled in method ''setvalue''',M.style)
        end
    end
end

% Misc
methods
    function set.visible(M,b)
        M.visible = fn_switch(b,'logical');
        set([M.hparent M.hu],'visible',fn_switch(b,'on/off')) %#ok<*MCSUP>
    end
    function set.enabled(M,b)
        M.enabled = fn_switch(b,'logical');
        set([M.hparent M.hu],'enabled',fn_switch(b,'on/off')) %#ok<*MCSUP>
    end
end

% Create control and return the graphic handle
methods (Static)
    function hu = createcontrol(varargin)
        M = fn_propcontrol(varargin{:});
        hu = M.hu;
    end
end

end
