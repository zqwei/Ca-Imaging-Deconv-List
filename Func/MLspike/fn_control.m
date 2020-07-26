classdef fn_control < hgsetget
    % function X = fn_control(s[,fun][,spec][,hparent] ...
    %   [,'okbutton|nobutton'][,'ncol',n][,'title',titl])
    % function fn_control('demo')
    %---
    % cluster of controls representing the structure s (changing the
    % control changes the values in X, and changing the values in X
    % automatically updates the control display)
    %
    % Input:
    % - s           structure to intialize X; s can also be a 2-element
    %               structure, standing for [s spec]
    % - fun         function with prototype @(s)fun, which will be called
    %               by X
    % - spec        structure with additional information on the aspect and
    %               behavior of the controls (see below); it should have
    %               the same fields as s (though some fields can be
    %               omitted)
    % - hp          parent figure or uipanel where to create the controls
    %               (a new figure is created if not specified)
    % - 'okbutton' or 'nobutton'
    %               specifically specify to have an ok button or no button
    %
    % Output:
    % - X           a fn_control object, which can be manipulated using
    %               usual structure syntax
    % 
    % Possible values for the fields of spec:
    % []            automatic guess how to display the control
    % 'logical'     check box
    % 'multcheck [n]' array of n check boxes
    % {'multcheck|multlist' 'str1' 'str2' ...}
    %               array of n check boxes or list display - specify the
    %               name of each box/list entry
    % {'str1' 'str2' ...}       
    %               popup menu with specified string values
    % {['list|radio|button'] 'str1','str2',...}       
    %               specification of the type of display [default: list]
    %               for a choice between string values
    %               if one option is the empty string and style is 'radio'
    %               or 'button', this option will correspond to no button
    %               pressed
    % 'char [n [nlin]]'    
    %               input for string, if n is specified, sets the minimal
    %               length of the input in number of characters, otherwise,
    %               minimal length is set according to the value in s
    %               if nlin is specified, control occupies nlin lines
    %               instead of 1
    % 'double [n]'  input for numerical array
    % 'single [n]'  input for numerical array
    % 'slider min max [step] [format]'
    %               slider, specify min, max, step (optional) and format of the
    %               string representation (optional)
    % 'logslider min max [step] [format]'
    %               logarithmic scale slider (min and max should be the log of
    %               the effective min and max)
    % 'loglogslider min max [step] [format]'
    %               logarithmic scale slider, with possibility to select
    %               also a negative number
    % 'stepper [n [min [max [step [format]]]]]'
    %               input for n double
    %               if n>1, it is possible to define n values for min, max,
    %               step, separated by commas, for example: 0,-Inf,-1
    % 'clip'        input for 2-elements vector (usually, min and max);
    %               move the mouse in the control area to change the value
    % 'color'       a small color table to select most-common color and
    %               grayscale values
    % 'xdouble, xsingle, xchar [n], x[log[log]]slider min max [..],
    % xstepper, xclip, xcolor'
    %               additional display of a check box: value will be empty
    %               if the box is not checked
    %               it is possible to specify a default value inside
    %               brackets at the end of the flag, for example:
    %               'xchar 12 [yes we can]' (here the brackets do not mean
    %               that this starting value is optional, but they must
    %               appear in the string)
    % 'file|dir'    button for selecting file name / directory name
    % 'label [nlin]' field name will be displayed (usually labels a new
    %               section) but does not correspond to any data
    %               if nlin is specified, control occupies nlin lines
    % 'struct' or full specification sub-structure
    %               button to edit the sub-structure
    % 'hide'        value is not displayed
    % 'readonly [n]'
    %               read-only display of value as a string
    % {'push' 'str1','str2',...}
    %               create array of push buttons that will cause an action
    %               to be launched
    %               in this case callback fun will be called with action
    %               string as an argument (instead of structure s)
    %
    % Specification can be followed with a sequence '< name', indicating
    % that the control of interest should be enabled only if a preceding
    % control with name 'name' has value true (logical control) or
    % non-empty value (other controls).
    % 
    % One might want to display small sentences rather than simple names
    % when prompting user. For this, the following syntaxes are allowed:
    % - the sequence '__' in the field names will be replace by a space in
    %   the display 
    % - alternatively, spec can be a 2-elements structure (or s a
    %   3-elements structures), the second element containing the long-name
    %   version for each field.
    %
    % Example: 
    % Type 'fn_control demo' or simply 'fn_control' for a small
    % example.
    %
    % See also fn_structedit, fn_input, fn_propcontrol
    
    % Thomas Deneux
    % Copyright 2007-2017
    
    properties
        fun
        immediateupdate
    end
    properties (SetAccess='private')
        mode              % which special buttons: 'none', 'ok', 'execfun' 
        controls
        names
        dependencies
        entries
        hp
        himupd
        fignew
        changedfields
    end
    
    properties (Dependent)
        s
    end
    
    events
        OK
    end
    
    % Constructor
    methods
        function X = fn_control(s,varargin)
            
            %-
            % INITIALIZATION
            %-
            
            % demo
            if nargin==0 || (ischar(s) && strcmp(s,'demo'))
                [s varargin] = demo;
            end
            
            % Input
            X.hp = []; spec = struct; nicenames = struct; ncolumn = []; titl = 'Edit parameters';
            % (original structure)
            if ~isstruct(s)
                error 'first argument must be a structure'
            elseif isvector(s) && ismember(length(s),[2 3])
                spec = s(2);
                if length(s)==3, nicenames = s(3); end
                s = s(1);
            elseif ~isscalar(s)
                error('input structure must be scalar or have 2 or 3 elements')
            end
            % (other inputs)
            i = 0;
            while i<length(varargin)
                i = i+1;
                a = varargin{i};
                if ischar(a)
                    switch a
                        case {'ok' 'okbutton'}
                            % flag for the presence of an 'ok' button
                            X.mode = 'ok';
                        case 'nobutton'
                            X.mode = 'none';
                        case 'ncol'
                            i = i+1;
                            ncolumn = varargin{i};
                        case 'title'
                            i = i+1;
                            titl = varargin{i};
                    end
                elseif isa(a,'function_handle')
                    % callback function
                    X.fun = a;
                elseif isstruct(a)
                    % specifications
                    spec = a(1);
                    if length(a)==2
                        nicenames = a(2);
                    elseif ~isscalar(a)
                        error 'specification structure must be scalar or have 2 elements'
                    end
                elseif ishandle(a) || fn_isfigurehandle(a)
                    % parent object (figure or panel)
                    X.hp = a;
                else 
                    error argument
                end
            end
            % (some initializations)
            if isempty(X.mode)
                X.mode = fn_switch(isempty(X.fun),'none','execfun');
            end
            X.fignew = isempty(X.hp);
            X.entries = struct;
            
            % Gather and order field names
            names1 = fieldnames(s)';
            names2 = fieldnames(spec)';
            if all(fn_ismemberstr(names1,names2))
                % spec is complete -> use spec for ordering
                X.names = names2;
            elseif all(fn_ismemberstr(names2,names1))
                % spec is complete -> use spec for ordering
                X.names = names1;
            else
                % neither s or spec is complete -> do as smart as possible
                spec2s = fn_map(@(str)find(strcmp(str,names1)),names2,'cell');
                if all(diff([spec2s{:}])>0)
                    X.names = cell(1,length(names1)+length(setdiff(names2,names1)));
                    kx = 1;
                    ks = 1;
                    for idx=1:length(names2)
                        if ~isempty(spec2s{idx})
                            X.names(kx+(0:spec2s{idx}-ks-1)) = names1(ks:spec2s{idx}-1);
                            kx = kx + spec2s{idx}-ks;
                            ks = spec2s{idx}+1;
                        end
                        X.names(kx) = names2(idx);
                        kx = kx+1;
                    end
                    X.names(kx:end) = names1(ks:end);
                else
                    X.names = [names1 setdiff(names2,names1)];
                end
            end
            nf = length(X.names);           
            
            % Make a general structure with a lot of information
            X.controls = struct('name',{},'nicename',{},'label',{},'string',{}, ...
                'type',{},'style',{},'value',{}, ...
                'startval',{},'defaultcheck',{},'defaultstring',{}, ...
                'n_name',{},'n_val',{},'n_line',{},'hname',{},'hval',{}, ...
                'check',{},'log',{},'min',{},'max',{},'step',{},'shift',{},'format',{}, ...
                'mode',{},'values',{} ...
                );
            X.dependencies = false(nf);
            
            %-
            % SET PARAMETERS  
            % fill the structure with all necessary parameters but do not
            % display the controls yet
            %-
            
            for k=1:nf
                f = X.names{k};
                X.entries.(f) = k;
                X.controls(k).name = f;
                xk = X.controls(k);
                
                % [start value]
                if isfield(s,f)
                    xk.value = s.(f);
                else
                    xk.value = [];
                end
                
                % [specification]
                if isfield(spec,f) && ~isempty(spec.(f))
                    opt = spec.(f); 
                else
                    if isnumeric(s.(f))
                        opt = class(s.(f));
                    else
                        opt = fn_switch(class(s.(f)), ...
                            'logical',  'logical', ...
                            'char',     'char', ...
                            'struct',   'struct', ...
                            'function_handle',  'readonly', ...
                            'unknown');
                    end
                end

                % [field name]
                xk.name = f;
                if isfield(nicenames,f) && ~isempty(nicenames.(f))
                    xk.nicename = nicenames.(f);
                else
                    xk.nicename = strrep(f,'__',' ');
                end
                if strcmp(xk.style,'pushbutton')
                    xk.n_name = 0;
                else
                    xk.n_name = length(xk.nicename);
                end
                
                % [value type and control style]
                xk.label = false;
                if iscell(opt)
                    % (list of strings)
                    xk.check = false;
                    switch opt{1}
                        case {'list' 'radio' 'button'}
                            % format {'style','str1','str2',...}
                            xk.type = 'char';
                            xk.style = fn_switch(opt{1}, ...
                                'list',     'popupmenu', ...
                                'radio',    'radiobutton', ...
                                'button',   'togglebutton');
                            opt(1) = [];
                        case {'multcheck' 'multlist'}
                            % format {'multcheck|multlist','str1','str2',...}
                            xk.type = 'logical';
                            xk.style = opt{1};
                            opt(1) = [];
                        case 'push'
                            xk.type = 'action';
                            xk.style = 'pushbutton';
                            opt(1) = [];
                        otherwise
                            % format {'str1','str2',...}, default style is 'list'
                            xk.type = 'char';
                            xk.style = 'popupmenu';
                    end
                    xk.defaultcheck = true;
                elseif isstruct(opt)
                    xk.type = 'struct';
                    xk.style = 'struct';
                else
                    % (string describing the control)
                    [type args defval dep] = fn_regexptokens(opt,'^([^ ]+)([^\[<]*)(\[.*\])*( *<.*)*$');
                    opt = [type args];
                    % check box?
                    if type(1) == 'x'
                        xk.check = true;
                        type(1) = [];
                        % initial checking of the box
                        xk.defaultcheck = ~isempty(xk.value);
                    else
                        xk.check = false;
                        xk.defaultcheck = true;
                    end
                    % define value type and display style
                    switch type
                        case 'label'
                            xk.style = 'label';
                            xk.label = true;
                        case 'logical'
                            xk.type = 'logical';
                            xk.style = 'checkbox';
                            xk.check = true;
                        case 'multcheck'
                            xk.type = 'logical';
                            xk.style = type;
                        case 'multlist'
                            error 'multlist option should be passed in the form of a cell array, together with individual entry names'
                        case {'slider' 'logslider' 'loglogslider'}
                            xk.type = 'double';
                            xk.log = sum(logical(strfind(type,'log'))); % count how many 'log'
                            xk.style = 'slider';
                        case 'stepper'
                            xk.type = 'double';
                            xk.style = 'stepper';
                        case 'clip'
                            xk.type = 'double';
                            xk.style = 'sensor';
                            xk.mode = 'clip';
                        case 'color'
                            xk.type = 'double';
                            xk.style = 'color';
                        case {'file','dir'}
                            xk.type = 'char';
                            xk.style = 'file';
                            xk.mode = fn_switch(type,'file','save','dir','dir');
                        case {'char' 'double' 'single' 'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                            xk.type = type;
                            xk.style = 'edit';
                        case 'struct'
                            xk.type = 'struct';
                            xk.style = 'struct';
                        case 'readonly'
                            xk.type = class(xk.value);
                            xk.style = 'text';
                        case 'hide'
                            xk.type = class(xk.value);
                            xk.style = 'hide';
                        case 'unknown'
                            xk.style = 'exclude';
                        otherwise
                            error('unknown sub-control type: ''%s''',type)
                    end
                    
                    % starting value (will be set only if xk.value is
                    % empty!)
                    if ~isempty(defval) && isempty(xk.value)
                        str = fn_regexptokens(defval,'\[(.*)\]');
                        xk.startval = str2val(str,xk.type);
                    end
                    
                    % dependencie
                    if ~isempty(dep)
                        name = fn_regexptokens(dep,'< *([^ ]*)');
                        kdep = find(strcmp(name,X.names(1:k-1)));
                        if isempty(kdep)
                            error 'error in establishing dependency'
                        end
                        X.dependencies(kdep,k) = true;
                    end
                end
                
                % [initial value, control width, and style-specific parameters] 
                xk.n_line = 1;
                switch xk.style
                    case {'label' 'exclude'}
                        xk.n_val = 0;
                        args = regexp(opt,'[^ ]*','match');
                        if length(args)>=2 % nlin is specified
                            nlin = str2double(args{2});
                            if nlin<=0 || mod(nlin,1), error('number of lines must be a positive integer'), end
                            xk.n_line = nlin;
                            xk.n_name = xk.n_name / (2*nlin-1);
                        end
                    case 'checkbox'
                        % logical value - only check box
                        xk.n_val = 0;
                        if ~isempty(xk.value)
                            xk.startval = logical(xk.value);
                        elseif isempty(xk.startval)
                            % note that xk.value is empty, but no need to
                            % set it since it won't be used
                            xk.startval = false;
                        end
                    case {'multcheck' 'multlist'}
                        % number of entries and string
                        if iscell(opt)
                            nentry = length(opt);
                            xk.string = opt;
                        else
                            if strcmp(xk.style,'multlist'), error programming, end % this case has already been filtered out above
                            answer = regexp(opt,'([^ ]*)','tokens');
                            if length(answer)==2
                                nentry = str2double(answer{2});
                                if ~isempty(xk.value) && nentry~=length(xk.value)
                                    error('multcheck length specification does not match with value')
                                end
                            elseif ~isempty(xk.value)
                                nentry = length(xk.value);
                            else
                                nentry = 1;
                            end
                            xk.string = repmat({''},1,nentry);
                        end
                        xk.mode = nentry;
                        % initial value
                        switch xk.style
                            case 'multlist'
                                if isempty(xk.value)
                                    xk.value = false(1,nentry);
                                elseif ischar(xk.value) || iscell(xk.value)
                                    if ~all(ismember(xk.value,xk.string))
                                        error 'multlist: some entry is not in the list'
                                    end
                                    xk.value = find(ismember(xk.string,xk.value));
                                elseif isnumeric(xk.value)
                                    xk.value = logical(xk.value);
                                elseif ~islogical(xk.value)
                                    error 'incompatible format for ''multlist'' value'
                                end
                            case 'multcheck'
                                if isempty(xk.value)
                                    xk.value = false(1,nentry);
                                end
                        end
                        xk.startval = xk.value;                        
                        % width
                        xk.n_val = 3*xk.mode + sum(fn_map(@length,xk.string)); % not clear what is the minimum width
                        xk.format = '%i';
                        % height
                        if strcmp(xk.style,'multlist')
                            xk.n_line = xk.mode;
                        end
                    case {'popupmenu' 'radiobutton' 'togglebutton' 'pushbutton'}
                        % (list of strings)
                        % note that in this case, xk.startval has not been
                        % defined yet
                        if ~strcmp(xk.style,'pushbutton')
                            if ischar(xk.value)
                                xk.startval = find(strcmp(xk.value,opt));
                                if isempty(xk.startval), xk.startval = 1; end
                            else
                                if ~isequal(xk.value,[]), error 'value must be a string or []', end
                                xk.startval = 1;
                            end
                            xk.value = opt{xk.startval};
                        end
                        xk.values = opt;
                        args = char(opt{:}); 
                        switch xk.style
                            case 'popupmenu'
                                xk.n_val = 1+min(25,size(args,2))*.8;
                            case {'togglebutton' 'pushbutton'}
                                xk.n_val = length(opt) + numel(args)*.8;
                            case 'radiobutton'
                                xk.n_val = 4*length(opt) + numel(args)*.8;
                        end
                    case 'slider'
                        % remember: xk.value is in the regular scale, but
                        % xk.min, xk.max, xk.shift and xk.startval are in
                        % the regular/logarighmic/special logarithmic space
                        % depending on xk.log
                        
                        % starting value (only if xk.value is defined)
                        if ~isempty(xk.value)
                            switch xk.log
                                case 0
                                    xk.startval = xk.value;
                                case 1
                                    xk.startval = log10(xk.value);
                                case 2
                                    % complicate
                                    xk.startval = x2log(xk.value,xk.shift);
                            end
                        end
                        % read min and max, set startval if not done yet
                        answer = regexp(opt,'([^ ]*)','tokens');
                        answer = [answer{:}];
                        if length(answer)>=3
                            % note that, while xk.value is still in the
                            % regular space, 
                            xk.min = str2double(answer{2});
                            xk.max = str2double(answer{3});
                            if xk.log==2
                                xk.shift = str2double(answer{2});
                                xk.max = str2double(answer{3})-xk.shift;
                                xk.min = -xk.max;
                            end
                            if isempty(xk.startval)
                                xk.startval = (xk.min+xk.max)/2; 
                            end
                        elseif ~isempty(xk.startval)
                            switch xk.log
                                case 0
                                    if xk.startval>0
                                        xk.min = 0;
                                        xk.max = 2*xk.startval;
                                    elseif xk.startval==0
                                        xk.min = -1;
                                        xk.max = 1;
                                    elseif xk.startval<0
                                        xk.min = 2*xk.startval;
                                        xk.max = -2*xk.startval;
                                    end
                                case 1
                                    xk.min = xk.startval-1;
                                    xk.max = xk.startval+1;
                                case 2
                                    xk.shift = xk.startval-1;
                                    xk.max = 2;
                                    xk.min = -2;
                            end
                        else
                            switch xk.log
                                case 0
                                    xk.min = 0;
                                    xk.max = 1;
                                    xk.startval = 0;
                                case 1
                                    xk.min = -1;
                                    xk.max = 1;
                                    xk.startval = 0;
                                case 2
                                    xk.shift = -1;
                                    xk.max = 2;
                                    xk.min = -2;
                                    xk.startval = 0;
                            end
                        end
                        % read step and format
                        xk.step = 0;
                        xk.format = [];
                        for i=4:length(answer)
                            str = answer{i};
                            if strfind(str,'%')
                                xk.format = str;
                            else
                                xk.step = str2double(str);
                            end
                        end
                        if isempty(xk.format)
                            if xk.step>0 && ~mod(xk.step,1)
                                xk.format = '%.0f';
                            elseif xk.log
                                xk.format = '%.1g';
                            else
                                xk.format = '%.1f';
                            end
                        end
                        % increase the field length according to format
                        test1 = num2str(xk.max+rand,xk.format);
                        test2 = num2str(xk.min+rand,xk.format);
                        xk.n_name = xk.n_name + 2 + max(length(test1),length(test2)) + 1;
                        % second column
                        xk.n_val = 6;
                    case 'stepper'
                        % read options
                        defans = {'stepper' '1' '-Inf' 'Inf' '1' '%.2g'};
                        answer = regexp(opt,'([^ ]*)','tokens');
                        answer = [answer{:}];
                        missing = (length(answer)+1:length(defans));
                        answer(missing) = defans(missing);
                        xk.mode = str2double(answer{2}); % number of numeric values
                        xk.min  = str2num(['[' strrep(answer{3},',',' ') ']']); %#ok<ST2NM>
                        xk.max  = str2num(['[' strrep(answer{4},',',' ') ']']); %#ok<ST2NM>
                        xk.step = str2num(['[' strrep(answer{5},',',' ') ']']); %#ok<ST2NM>
                        xk.format = answer{6};
                        % starting value
                        if ~isempty(xk.value)
                            if isscalar(xk.value) && xk.mode>1
                                xk.startval = repmat(xk.value,[1 xk.mode]); 
                            else
                                xk.startval = xk.value;
                            end
                        elseif ~isempty(xk.startval)
                            if isscalar(xk.startval) && xk.mode>1
                                xk.startval = repmat(xk.startval,[1 xk.mode]); 
                            end
                        else
                            xk.startval = ones(1,xk.mode) .* xk.min;
                        end
                        % width
                        xk.n_val = 5*xk.mode; % not clear what is the minimum width
                    case 'sensor'
                        if ~isempty(xk.value)
                            xk.startval = xk.value;
                        elseif isempty(xk.startval)
                            xk.startval = [0 1];
                        end
                        xk.n_val = 10; % not clear what is the minimum width
                    case 'color'
                        [colors ncol] = fn_colorset('prism9');
                        colors = [colors; gray(ncol-1); 0 0 0]; %#ok<AGROW>
                        colors = fn_reshapepermute(colors,[ncol 2 3],[2 1 3]);
                        xk.values = colors;
                        if ~isempty(xk.value)
                            col = xk.value;
                        elseif isempty(xk.startval)
                            col = [0 0 0];
                        end
                        [xk.startval xk.values] = col2idx(col,colors);
                        xk.n_val = 10; % not clear what is the minimum width
                    case {'edit' 'text'}
                        if ~isempty(xk.value)
                            xk.startval = val2str(xk.value); 
                        elseif isempty(xk.startval)
                            xk.startval = '';
                        end
                        args = regexp(opt,'[^ ]*','match');
                        if length(args)>=2 % length is specified
                            xk.n_val = str2double(args{2});
                        else
                            xk.n_val = max(4,length(xk.startval));
                        end
                        if strcmp(xk.type,'char') && length(args)>=3
                            nlin = str2double(args{3});
                            if nlin<=0 || mod(nlin,1), error('number of lines must be a positive integer'), end
                            xk.n_line = nlin;
                            xk.n_val = xk.n_val+8;
                        end
                    case 'file'
                        if ~isempty(xk.value) && exist(xk.value,'file')
                            xk.startval = xk.value;
                        else
                            xk.startval = '';
                        end
                        xk.n_val = 20;
                    case 'struct'
                        xk.startval = xk.value;
                        if isstruct(opt), xk.mode = opt; end
                        xk.n_val = 12;
                        xk.check = false;
                    case 'hide'
                        xk.check = false;
                        xk.n_val = 0;
                        xk.n_line = 0;
                end
                X.controls(k) = xk;
            end
            
            %-
            % POSITIONNING
            %-
            
            % Width of the two columns
            idx = logical([X.controls.n_val]); % ignore fields which do not have two columns
            if X.fignew
                htest = figure('visible','off');
            else
                htest = X.hp;
            end
            utest = uicontrol('parent',htest,'visible','off','fontunit','pixel');
            fsz = get(utest,'fontsize');
            if X.fignew, close(htest), else delete(utest), end
            fw = fsz * .6; % font width is approximately 3/5 of font height
            n0 = 5 + [X.controls(~idx).check]*15 + [X.controls(~idx).n_name]*fw;
            n1 = 5 + [X.controls(idx).check]*15 + [X.controls(idx).n_name]*fw;
            n2 = 20 + [X.controls(idx).n_val]*fw;
            A0 = max(n0);   % width for name (controls without value)
            if isempty(A0), A0=1; end
            A = max(n1);    % width for name (controls with value)
            if isempty(A), A=1; end
            B = max(n2);    % width for value
            if isempty(B), B=1; end
            
            % Position parameters 
            D = 5; E = 10;  % horizontal and vertical spacing
            G = 45; L = 80; % width of update buttons
            K = 20; T = 17; % height of general and text buttons
            nbut = sum([X.controls.n_line]) + ~strcmp(X.mode,'none');
            if X.fignew
                % new figure
                if isempty(ncolumn), ncol = 1; else ncol = ncolumn; end
                nlin = ceil(nbut/ncol);
                ss = get(0,'screensize');
                Z = max([A0, A+D+B+D, ...                                        % maximal width of normal buttons
                    fn_switch(X.mode,'execfun',G+D+L+D,'ok',G+D,'none',0)]); % width of special button
                if A+D+B+D<Z
                    A = (Z-2*D)*(A/(A+B));
                    B = (Z-2*D)-A;
                end
                W = D+ncol*Z;
                H = E+nlin*(K+E);
                H = H+20; % BUG with Exceed
                p = get(0,'pointerLocation');
                LEFT   = min(max(p(1)-W/2,20),ss(3)-W-20);
                BOTTOM = min(max(p(2)-H/2,50),ss(4)-H-20);
                posp = [LEFT BOTTOM W H];
                X.hp = figure('numbertitle','off','name',titl, ...
                    'createfcn','', ... % avoid fn_figmenu!
                    'menubar','none', ...
                    'integerhandle','off','handlevisibility','off', ...
                    'position',posp, ...
                    'defaultuicontrolhorizontalalignment','left');
            else
                % check size of parent
                switch get(X.hp,'type')
                    case 'figure'
                        posp = get(X.hp,'position');
                    case 'uipanel'
                        oldunit = get(X.hp,'units');
                        set(X.hp,'units','pixel')
                        posp = get(X.hp,'position');
                        set(X.hp,'units',oldunit);
                    otherwise
                        error('containter must be a figure or a uipanel object')
                end
                Z = max([A0, A+D+B+D, ...                                        % maximal width of normal buttons
                    fn_switch(X.mode,'execfun',G+D+L+D,'ok',G+D,'none',0)]); % width of special button
                Y = K+E;
                xrep = (posp(3)-D)/Z;
                yrep = (posp(4)-D)/Y;
                if floor(xrep)*floor(yrep)>=nbut
                    % it fits
                    ncol = ceil(nbut/floor(yrep));
                    nlin = ceil(nbut/ncol);
                    B = (posp(3)-D)/ncol-(A+D+D);
                elseif floor(xrep)*floor(yrep/.7)>=nbut
                    % it fits when squeezed a bit vertically
                    ncol = floor(xrep);
                    nlin = ceil(nbut/ncol);
                    B = (posp(3)-D)/ncol-(A+D+D);
                    K = 17;
                    E = min(10,(posp(4)-nlin*K)/(nlin+1));
                elseif ceil(xrep)*floor(yrep/.7)>=nbut
                    % it fits when squeezed a bit vertically and horizontally
                    ncol = ceil(xrep);
                    nlin = ceil(nbut/ncol);
                    D = 3;
                    if A/2 > B/3
                        A = (posp(3)-D)/ncol-(B+D+D);
                    end
                    B = (posp(3)-D)/ncol-(A+D+D);
                    K = 17;
                    E = min(10,(posp(4)-nlin*K)/(nlin+1));
                else
                    if yrep>1.5,  warning('cannot fit the buttons inside the container'), end
                    % make a single line, possibly squeezing a lot
                    % horizontally
                    ncol = nbut;
                    nlin = 1;
                    D = 1;
                    A = min(A,(posp(3)-D)/ncol/3);
                    B = (posp(3)-D)/ncol-(A+D+D);
                    if posp(4)>=17
                        K = 17;
                        E = (posp(4)-K)/2;
                    else
                        K = posp(4)-1; T = posp(4)-1;
                        E = 0;
                    end
                end
            end
            delete(get(X.hp,'children'))
            fn_deletefcn(X.hp,@(hp,evnt)delete(X))
            set(X.hp,'tag','fn_control') % prevent access to fn_imvalue
            
            % Updated sizes
            set(X.hp,'defaultuicontrolunits','pixel')
            X.changedfields = {};
            H = posp(4);
            Z = max(A+D+B+D, ...                                        % maximal width of normal buttons
                fn_switch(X.mode,'execfun',G+D+L+D,'ok',G+D,'none',0)); % width of special button
            Y = K+E;
            
            %             % Font size
            %             utest = uicontrol('parent',X.hp,'style','text','visible','off');
            %             set(utest,'fontunits','pixel')
            %             if get(utest,'fontsize')>T-2
            %                 set(X.hp,'defaultuicontrolfontunits','pixel','defaultuicontrolfontsize',T-2)
            %             end
            %             delete(utest)
            
            %-
            % DISPLAY 
            %-
            
            % Color
            bgcol = get(X.hp,fn_switch(get(X.hp,'type'),'figure','color','uipanel','backgroundcolor'));
            bgcollabel = [1 1 1]*.6;

            % Display controls
            ipos = 1;
            for k=1:nf
                xk = X.controls(k);
                icol = 1+floor((ipos-1)/nlin);
                ilin = ipos-(icol-1)*nlin;
                ipos = ipos + xk.n_line; % position for next control
                if strcmp(xk.style,'hide')
                    % nothing to display
                elseif ~xk.n_val
                    % first column only (label or checkbox)
                    xk.hname = uicontrol( ...
                        'parent',X.hp,'backgroundcolor',bgcol, ...
                        'string',xk.nicename, ...
                        'position',[D+(icol-1)*Z H-(ilin+xk.n_line-1)*Y A+D+B K+(xk.n_line-1)*Y]);
                    set(xk.hname,'units','normalized');
                    switch xk.style
                        case 'label'
                            set(xk.hname,'style','text','backgroundcolor',bgcollabel);
                        case 'exclude'
                            set(xk.hname,'style','text');
                        case 'checkbox'
                            set(xk.hname,'style','checkbox', ...
                                'value',xk.startval, ...
                                'callback',@(hu,evnt)chgvalue(X,k));                           
                        otherwise
                            error programming
                    end
                else
                    % first column
                    if ~strcmp(xk.style,'pushbutton')
                        xk.hname = uicontrol('style','text','string',xk.nicename, ...
                            'horizontalalignment','left', ...
                            'parent',X.hp,'backgroundcolor',bgcol, ...
                            'position',[D+(icol-1)*Z H-ilin*Y A T]);
                        set(xk.hname,'units','normalized');
                    end
                    if xk.check
                        set(xk.hname,'style','checkbox','value',xk.defaultcheck);
                        set(xk.hname,'callback',@(hu,evnt)chgvalue(X,k,logical(get(hu,'value'))));
                    end
                    if strcmp(xk.style,'slider') && (~xk.check || xk.defaultcheck)
                        set(xk.hname,'string',[xk.nicename ' (' num2str(xk.value,xk.format), ')'])
                    end
                    
                    % second column
                    switch xk.style
                        case 'popupmenu'
                            xk.hval = uicontrol('parent',X.hp,'style',xk.style, ...
                                'position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'string',xk.values,'value',xk.startval, ...
                                'callback',@(hu,evnt)chgvalue(X,k));
                        case {'radiobutton' 'togglebutton' 'pushbutton'}
                            compactstyle = strrep(xk.style,'button','');
                            if strcmp(xk.style,'pushbutton')
                                callback = X.fun;
                            else
                                callback = @(x)chgvalue(X,k);
                            end
                            xk.hval = fn_buttongroup(compactstyle,xk.values,callback, ...
                                'parent',X.hp, ...
                                'units','pixel','position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'value',xk.startval);
                            set(xk.hval.panel,'borderwidth',0,'backgroundcolor',bgcol)
                            set(xk.hval.buttons,'backgroundcolor',bgcol)
                        case 'multcheck'
                            xk.hval = fn_multcheck(xk.string,'parent',X.hp, ...
                                'position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'value',xk.startval,'callback', ...
                                @(hu,evnt)chgvalue(X,k));
                        case 'multlist'
                            xk.hval = uicontrol('style','listbox','string',xk.string,'parent',X.hp, ...
                                'position',[D+(icol-1)*Z+A+D H-(ilin+xk.n_line-1)*Y B K+(xk.n_line-1)*Y], ...
                                'max',2,'value',xk.startval,'callback', ...
                                @(hu,evnt)chgvalue(X,k));
                        case 'slider'
                            xk.hval = fn_slider('parent',X.hp,'mode','point', ...
                                'position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'min',xk.min,'max',xk.max,'width',.1, ...
                                'value',xk.startval,'callback', ...
                                @(hu,evnt)chgvalue(X,k));
                            if xk.step
                                % note that 'inc' and 'width are relative values (betw.
                                % 0 and 1, not betw. min and max)
                                inc = xk.step/(xk.max-xk.min);
                                set(xk.hval,'inc',inc,'width',inc)
                            end
                        case 'stepper'
                            xk.hval = fn_stepper('parent',X.hp, ...
                                'position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'backgroundcolor','w', ...
                                'min',xk.min,'max',xk.max,'step',xk.step, ...
                                'format',xk.format, ...
                                'value',xk.startval,'callback', ...
                                @(hu,evnt)chgvalue(X,k));
                        case 'sensor'
                            xk.hval = fn_sensor('parent',X.hp,'mode',xk.mode, ...
                                'backgroundcolor',[.5 .6 .6], ... 
                                'position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'value',xk.startval, ...
                                'format','%.4g', ...
                                'callback',@(hu,evnt)chgvalue(X,k));
                        case 'color'
                            s = struct;
                            s.ha = axes('parent',X.hp, ...
                                'units','pixel','position',[D+(icol-1)*Z+A+D H-ilin*Y B K]);
                            s.im = image(xk.values,'parent',s.ha,'hittest','off');
                            s.pt(1) = line(xk.startval(2),xk.startval(1),'parent',s.ha, ...
                                'linestyle','none','marker','.','markersize',16,'color','k', ...
                                'hittest','off');
                            s.pt(2) = line(xk.startval(2),xk.startval(1),'parent',s.ha, ...
                                'linestyle','none','marker','.','markersize',7,'color','w', ...
                                'hittest','off');
                            set(s.ha, ...
                                'xtick',[],'ytick',[], ...
                                'buttondownfcn',@(hu,evnt)chgvalue(X,k));
                            xk.hval = s;
                        case {'edit' 'text'}
                            xk.hval = uicontrol('parent',X.hp,'style',xk.style, ...
                                'position',[D+(icol-1)*Z+A+D H-(ilin+xk.n_line-1)*Y B K+(xk.n_line-1)*Y], ...
                                'horizontalalignment','left', ...
                                'max',xk.n_line, ... % allow multiple lines if n_line>1
                                'string',val2str(xk.startval),'backgroundcolor','w', ...
                                'callback',@(hu,evnt)chgvalue(X,k));
                        case 'file'
                           xk.hval = fn_filecontrol('parent',X.hp, ... 
                                'position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'mode',xk.mode, ...
                                'string',xk.startval, ...
                                'callback',@(hu,evnt)chgvalue(X,k));
                        case 'struct'
                            xk.hval = uicontrol('parent',X.hp,'style','pushbutton', ...
                                'position',[D+(icol-1)*Z+A+D H-ilin*Y B K], ...
                                'string','Edit structure', ...
                                'callback',@(hu,evnt)chgvalue(X,k));
                        otherwise
                            error programming
                    end
                    if strcmp(xk.style,'color')
                        set(xk.hval.ha,'units','normalized')
                    else
                        set(xk.hval,'units','normalized')
                    end
                end
                X.controls(k) = xk;
                checkEnabled(X,[],k)
            end
            
            % Special action buttons
            switch X.mode
                case 'execfun'
                    X.immediateupdate = true;
                    uicontrol('style','pushbutton','string','Update','parent',X.hp, ...
                        'position',[D+ncol*Z-D-L-D-G H-nlin*Y G K], ...
                        'callback',@(hu,evnt)evalfun(X))
                    X.himupd = uicontrol('style','radiobutton','string','immediate', ...
                        'value',X.immediateupdate, ...
                        'parent',X.hp,'backgroundcolor',bgcol, ...
                        'position',[D+ncol*Z-D-L H-nlin*Y L K], ...
                        'callback',@(hu,evnt)set(X,'immediateupdate',get(hu,'value')));
                case 'ok'
                    X.immediateupdate = ~isempty(X.fun);
                    uicontrol('style','pushbutton','string','OK','parent',X.hp, ...
                        'position',[(ncol-1)*Z+(D+Z-G)/2 H-nlin*Y G K], ...
                        'callback',@(u,evnt)okpress);
                case 'none'
                    % no special buttons
                    X.immediateupdate = ~isempty(X.fun);
            end
            
            % nested function for when the OK button is pressed
            function okpress
                notify(X,'OK')
                % delete the controls now
                if X.fignew
                    close(X.hp)
                else
                    delete(get(X.hp,'children'))
                end
            end
            
            % no output?
            if nargout==0, clear X, end
            
        end
    end
    
    % Get/Set
    methods
        function s = get.s(X)
            okval = ~[X.controls.label];
            c = [X.names(okval); {X.controls(okval).value}];
            for k=1:sum(okval), if iscell(c{2,k}), c{2,k} = {c{2,k}}; end, end %#ok<CCAT1>
            s = struct(c{:});
        end
        function set.immediateupdate(X,value)
            set(X.himupd,'value',value) %#ok<*MCSUP>
            X.immediateupdate = value;
            if ~isempty(X.changedfields), evalfun(X), end
        end        
    end
    
    % Referencing, assignment, display
    methods
        function x = subsref(X,f)
            switch f(1).type
                case '()'
                    x = X(f(1).subs{:});
                case '.'
                    k = strcmp(X.names,f(1).subs);
                    if ~any(k)
                        x = X.(f(1).subs);
                    else
                        x = X.controls(k).value;
                    end
                otherwise
                    error('wrong referencing of fn_control object')
            end
            if length(f)>1, x = subsref(x,f(2:end)); end
        end
        function X = subsasgn(X,f,x)
            switch f(1).type
                case '()'
                    if length(f)>1
                        subsasgn(X(f(1).subs{:}),f(2:end),x);
                    else
                        X(f(1).subs{:}) = x;
                    end
                case '.'
                    k = strcmp(X.names,f(1).subs);
                    if strcmp(f(1).subs,'s')
                        if isempty(x), x = struct; end
                        if ~isscalar(f) || ~isstruct(x)
                            error 'incorrect syntax for assigning control values'
                        end
                        for i = 1:length(X.controls)
                            field = X.controls(i).name;
                            if isfield(x,field)
                                X.controls(i).value = x.(field);
                                updatecontrol(X,i)
                            end
                        end
                    elseif any(k)
                        if length(f)>1
                            X.controls(k).value = subsassgn(X.controls(k).value,f(2:end),x);
                        else
                            X.controls(k).value = x;
                        end
                        updatecontrol(X,k)
                    else
                        if length(f)>1
                            X.(f(1).subs) = subsassgn(X.(f(1).subs),f(2:end),x);
                        else
                            X.(f(1).subs) = x;
                        end
                    end
                otherwise
                    error('wrong referencing of fn_control object')
            end
        end
        function disp(X)
            disp(X.s)
        end
    end
    
    % Routines
    methods
        function evalfun(X)
            if ~isempty(X.fun), feval(X.fun,X.s), end
            if isvalid(X) && ishandle(X.hp), X.changedfields = {}; end
        end
        function chgvalue(X,k,bval)
            % callback function executed when control k has been changed
            xk = X.controls(k);
            
            % get the value if we checked the box / check the box if we
            % changed the value
            if nargin>=3
                if ~xk.check || strcmp(xk.style,'checkbox') || ~islogical(bval), error programming, end
                if bval
                    switch xk.style
                        case 'color'
                            rawval = [get(xk.hval.pt(1),'ydata') get(xk.hval.pt(1),'xdata')];
                        case 'edit'
                            rawval = get(xk.hval,'string');
                        otherwise
                            rawval = get(xk.hval,'value');
                    end
                else
                    if strcmp(xk.type,'char')
                        rawval = '';
                    else
                        rawval = [];
                    end
                end
            else
                % check the box
                if xk.check && ~strcmp(xk.style,'checkbox')
                    set(xk.hname,'value',true)
                end
                
                % get the 'raw' value
                switch xk.style
                    case 'checkbox'
                        rawval = get(xk.hname,'value');
                    case 'multlist'
                        rawval = false(1,xk.mode);
                        rawval(get(xk.hval,'value')) = true;
                    case 'color'
                        s = size(xk.values);
                        p = get(xk.hval.ha,'currentpoint');
                        rawval = fn_coerce(round(p(1,[2 1])),1,s(1:2));
                    case {'edit' 'file'}
                        rawval = get(xk.hval,'string');
                    case 'struct'
                    otherwise
                        rawval = get(xk.hval,'value');
                end
            end
            
            % value and special actions
            switch xk.style
                case 'checkbox'
                    val = logical(rawval);
                case 'popupmenu'
                    val = xk.values{rawval};
                case 'edit' 
                    val = str2val(rawval,xk.type);
                    % string did not evaluate correctly?
                    if ~strcmp(xk.type,'char') && any(isnan(val(:)))
                        % set the control back to its previous value
                        set(xk.hval,'string',val2str(xk.value))
                        return
                    end
                case 'slider'
                    % logarithmic value
                    switch xk.log
                        case 0
                            val = rawval;
                        case 1
                            val = 10^rawval;
                        case 2
                            % complicate
                            val = log2x(rawval,xk.shift);
                    end
                    % text update
                    if isempty(val)
                        set(xk.hname,'string',xk.nicename)
                    else
                        set(xk.hname,'string', ...
                            [xk.nicename ' (' num2str(val,xk.format) ')'])
                    end
                case 'file'
                    val = rawval;
                    if isequal(val,0), return, end
                    set(xk.hval,'string',val)
                case 'color'
                    hf = fn_parentfigure(X.hp);
                    if strcmp(get(hf,'selectionType'),'open')
                        % special: define custom color
                        s = size(xk.values); 
                        rawval = s(1:2);
                        col = shiftdim(xk.values(rawval(1),rawval(2),:),1);
                        if isempty(col), return, end
                        xk.values(rawval(1),rawval(2),:) = shiftdim(uisetcolor(col),-1);
                        X.controls(k) = xk;
                        % update display
                        set(xk.hval.im,'cdata',xk.values)
                    end
                    if isempty(rawval)
                        val = [];
                    else
                        val = shiftdim(xk.values(rawval(1),rawval(2),:),1);
                    end
                    % move point
                    if ~isempty(rawval), set(xk.hval.pt,'xdata',rawval(2),'ydata',rawval(1)), end
                case 'struct'
                    if isstruct(xk.mode)
                        val = fn_structedit(xk.value,xk.mode);
                    else
                        val = fn_structedit(xk.value);
                    end
                    if isempty(val) || isequal(val,xk.value), return, end
                case 'text'
                    error 'programming: we should not enter this function for a read-only ''text'' control'
                otherwise
                    val = rawval;
            end
            
            % store the information on which fields were changed
            X.changedfields = union(X.changedfields,xk.name);

            % update value and dependencies
            X.controls(k).value = val;
            X.checkEnabled(k)
            
            % eval function
            if X.immediateupdate
                evalfun(X)
            end
        end
        function updatecontrol(X,k)
            % update display of control k (normally, upon a change of the
            % related value)
            xk = X.controls(k);
            % check the box according to whether the value is empty
            if xk.check && ~strcmp(xk.style,'checkbox')
                set(xk.hname,'value',~isempty(xk.value))
            end
            % change value display
            switch xk.style
                case 'checkbox'
                    % logical
                    set(xk.hname,'value',xk.value)
                case 'popupmenu'
                    idx = find(strcmp(xk.values,xk.value));
                    if isempty(idx)
                        idx = 1; 
                        fprintf('warning: value ''%s'' does not exist, replaced by ''%s''\n',xk.value,xk.values{1});
                        xk.value = xk.values{idx};
                    end
                    set(xk.hval,'value',idx);
                case {'radiobutton' 'togglebutton'}
                    if ~ischar(xk.value), error 'value must be a string', end
                    set(xk.hval,'value',xk.value);
                case 'multcheck'
                    set(xk.hval,'value',xk.value)
                case 'multlist'
                    set(xk.hval,'value',find(xk.value))
                case 'slider'
                    if isempty(xk.value)
                        set(xk.hname,'string',xk.name)
                    else
                        set(xk.hname,'string',[xk.name ...
                            ' (' num2str(xk.value,xk.format), ')'])
                        switch xk.log
                            case 0
                                val = xk.value;
                            case 1
                                val = log10(xk.value);
                            case 2
                                % complicate
                                val = x2log(xk.value,xk.shift);
                        end
                        set(xk.hval,'value',val);
                        % update, in case of coercing actions!
                        val = get(xk.hval,'value');
                        switch xk.log
                            case 0
                                X.controls(k).value = val;
                            case 1
                                X.controls(k).value = 10^val;
                            case 2
                                % complicate
                                X.controls(k).value = log2x(val,xk.shift);
                        end
                    end
                case {'stepper','sensor'}
                    if ~isempty(xk.value)
                        set(xk.hval,'value',xk.value)
                    end
                case 'color'
                    if ~isempty(xk.value)
                        [idx xk.values] = col2idx(xk.value,xk.values);
                        set(xk.hval.im,'cdata',xk.values)
                        set(xk.hval.pt,'xdata',idx(2),'ydata',idx(1))
                    end
                    if ischar(xk.value)
                        idx = [get(xk.hval.pt(1),'ydata') get(xk.hval.pt(1),'xdata')];
                        xk.value = shiftdim(xk.values(idx(1),idx(2),:),1);
                    end
                    X.controls(k) = xk;
                case {'edit' 'text'}
                    set(xk.hval,'string',val2str(xk.value));
                case 'file'
                    set(xk.hval,'string',xk.value);
                case 'struct'
                    % no need to do anything: the control itself does not
                    % contain the value
                case 'hide'
                    % nothing to do
                otherwise
                    error programming
            end
        end
        function checkEnabled(X,kdep,kk)
            if isempty(kdep)
                kdep = find(X.dependencies(:,kk));
                if isempty(kdep), return, end
            elseif nargin<3 || isempty(kk)
                kk = find(X.dependencies(kdep,:));
            end
            xkdep = X.controls(kdep);
            if strcmp(xkdep.type,'logical')
                enable = xkdep.value;
            else
                enable = ~isempty(xkdep.value);
            end
            for k = row(kk)
                xk = X.controls(k);
                % Enable name
                set(xk.hname,'enable',fn_switch(enable))
                % Enable control
                switch xk.style
                    case {'popupmenu' 'radiobutton' 'togglebutton' 'edit' 'text'}
                        set(xk.hval,'enable',fn_switch(enable))
                    case 'multcheck'
                    case 'multlist'
                    case 'slider'
                        xk.hval.enabled = enable;
                    case 'stepper'
                    case 'sensor'
                    case 'color'
                    case 'file'
                end
            end
        end
    end
        
    % Misc
    methods
        function access(X) %#ok<MANU>
            keyboard
        end
    end
end


%---
function [str type] = val2str(val)

type = class(val);
switch type
    case 'char'
        str = val;
    case 'function_handle'
        str = char(val);
        if str(1)~='@'; str = ['@' str]; end
    case {'double','single','logical','uint8','uint16','uint32','uint64','int8','int16','int32','int64'}
        [str errormsg] = fn_chardisplay(val);
        if ~isempty(errormsg), error(errormsg), end
    case 'cell'
        % special! cell array of strings
        type = 'char';
        str = val;
    otherwise
        error('cannot display object of class ''%s''',type)
end

end

%---
function val = str2val(str,type)

switch type
    case 'char'
        val = str;
    case {'double','single','logical'}
        try val = evalin('base',['[' str ']']); catch, val = NaN; end %#ok<CTCH>
    otherwise
        error programming
end

end

%---
function [idx colors] = col2idx(col,colors)

if ischar(col)
    hf = figure('visible','off','color',col);
    col = get(hf,'color');
    delete(hf)
end
col = shiftdim(col,-1);
b = fn_eq(col,colors,'all');
if ~any(b)
    idx = size(colors); idx = idx(1:2);
    colors(idx(1),idx(2),:) = col;
else
    [i j] = find(b,1);
    idx = [i j];
end

end

%---
function val = x2log(x,shift)

if x==0
    val=0;
elseif x>0
    val = max(0,log(x)-shift);
else
    val = min(0,-(log(-x)-shift));
end

end

%---
function x = log2x(val,shift)

if val==0
    x = 0;
elseif val>0
    x = 10^(val+shift);
else
    x = -10^(-val+shift);
end

end

%---
function [s args] = demo %#ok<STOUT>

C = {'s = struct(''a'',0,''b'',false,''c'',[],''d'',''hello'',''e'',[0 1],''f'',pwd,''g'',''red'',''h'',[0 1]);'
    'spec = struct(''c'',''xslider 0 10 1 [2] < b'',''d'',{{''hello'',''yo''}},''e'',''clip'',''f'',''dir'',''g'',''color'',''h'',{{''multcheck'' ''mom'' ''dad''}});'
    'myfun = @disp;'
    'fn_control(s,spec,myfun);'};
for k=1:4, disp(C{k}), end
for k=1:3, evalin('base',C{k}), eval(C{k}), end
args = {spec myfun};

end