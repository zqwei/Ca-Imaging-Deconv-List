classdef windowcallbackmanager < hgsetget
    % class 'windowcallbackmanager' is used for example by function
    % fn_scrollwheelregister, but is not supposed to be used by users
    %
    % See also fn_scrollwheelregister, fn_buttonmotion
    
    % Thomas Deneux
    % Copyright 2015-2017

    % Note on 'queuing' system: if an action is already active, new actions
    % are canceled, but the number of scroll wheel counts is memorized so
    % that it will be added to the next action when system will not be busy
    % any more
    
    properties (SetAccess='private')
        hf
        objects     % structure with information about figure and its children (handle, position, callback...)
        scrollcount % buffer to memorize number of scrolls when actions are canceled
        busy
        activekeys = {};
        cursize = [0 0];
        scrollmap_internal  % internal 'scroll map', might be empty if not yet computed
    end
    properties (Dependent, SetAccess='private')
        scrollmap   % map of to which registered child does every pixel of the figure belong
    end
    
    % Initialization
    methods
        function W = windowcallbackmanager(hf)
            % is there already an existing object for this figure?
            if isappdata(hf,'windowcallbackmanager')
                W = getappdata(hf,'windowcallbackmanager');
                % discard unvalid objects
                badidx = ~ishandle([W.objects.hobj]);
                W.objects(badidx) = [];
                return
            end
            
            % figure properties
            if ~isempty(get(hf,'windowscrollwheelfcn'))
                error 'a scroll wheel function already exists in figure'
            end
            setappdata(hf,'windowcallbackmanager',W)
            set(hf,'windowscrollwheelfcn',@(h,e)scrollwheelaction(W,e))
            set(hf,'windowkeypressfcn',@(h,e)keyboardmonitor(W,e,'press'))
            set(hf,'windowkeyreleasefcn',@(h,e)keyboardmonitor(W,e,'release'))
            
            % init properties
            W.hf = hf;
            W.objects = struct( ...
                'hobj',     hf, ...
                'doscroll', true, ...
                'isdefault',false, ...
                'listener', [], ...
                'curpos',   [], ...
                'callback', '' ...
                );
            W.scrollcount = 0;
            W.busy = false;
            
            % handle change of figure position
            fn_pixelposlistener(hf,@(u,e)updatepos(W,'chgfigpos'))
        end
    end
    
    % Registration
    methods
        function register(W,hobj,callback,doscroll)
            if nargin<4, doscroll = true; end
            repair(W)
            kobj = find([W.objects.hobj]==hobj);
            if isempty(kobj)
                kobj = length(W.objects)+1;
                W.objects(kobj).hobj = hobj;
                W.objects(kobj).doscroll = doscroll && fn_switch(get(hobj,'visible'));
                % listeners
                fn_pixelposlistener(hobj,@(h,e)updatepos(W,'chgpos',hobj))
                connectlistener(hobj,W,'Visible','PostSet',@(h,e)setactive(W,hobj,fn_switch(get(hobj,'visible'))));
                if W.objects(kobj).doscroll, updatepos(W,'addnew',hobj), end
            end
            W.objects(kobj).callback = callback;
            W.objects(kobj).isdefault = false;
        end
        function setactive(W,hobj,value)
            repair(W)
            kobj = find([W.objects.hobj]==hobj);
            if isempty(kobj)
                if value
                    error('object is not registered')
                else
                    return
                end
            end
            W.objects(kobj).doscroll = value;
            if ~value && W.objects(kobj).isdefault
                W.objects(kobj).isdefault = false;
                W.objects(1).callback = [];
            end
            updatepos(W,fn_switch(value,'add','remove'),hobj)
        end
        function unregister(W,hobj)
            kobj = find([W.objects.hobj]==hobj);
            if isempty(kobj), return, end
            if W.objects(kobj).isdefault
                W.objects(kobj).isdefault = false;
                W.objects(1).callback = [];
            end
            updatepos(W,'remove',hobj)
            W.objects(kobj) = [];
        end
        function setdefault(W,hobj)
            repair(W)
            kobj = find([W.objects.hobj]==hobj);
            if isempty(kobj), error('object is not registered'), end
            W.objects(1).doscroll = true;
            W.objects(1).callback = W.objects(kobj).callback;
            [W.objects.isdefault] = deal(false);
            W.objects(kobj).isdefault = true;
        end
        function repair(W)
            set(W.hf,'windowscrollwheelfcn',@(h,e)scrollwheelaction(W,e))
            W.busy = false;
            W.scrollcount = 0;
        end
    end
    
    % Handle changes of positions
    methods
        function map = get.scrollmap(W)
            map = W.scrollmap_internal;
            if isempty(map)
                updatepos(W,'set')
                map = W.scrollmap_internal;
            end
        end
        function updatepos(W,flag,kobj)
            % function updatepos(W,'set|chgfigpos')
            % function updatepos(W,'add|chgpos|remove',hobj|kobj)
            
            % input
            if nargin<2, flag='set'; end
            if nargin>=3 && (~isnumeric(kobj) || mod(kobj,1)~=0)
                hobj = kobj;
                kobj = find([W.objects.hobj]==hobj);
            end
            
            % some variables
            siz = round(fn_pixelsize(W.hf));
            nobj = length(W.objects); 
            
            % special case: figure size has been changed but we are
            % executing a callback new to the change in position of a
            % child; we can leave it, since anyway a new updatepos(W,'set')
            % will be executed
            if strcmp(flag,'chgpos') && any(siz~=W.cursize)
                return
            end
            
            switch flag
                case 'addnew'
                    % add a new object on top of the map... only if the map
                    % is built already
                    if ~isempty(W.scrollmap_internal)
                        pos = round(fn_pixelpos(hobj,'recursive'));
                        mask = false(siz); mask(pos(1):pos(2),pos(3):pos(4)) = true;
                        W.objects(kobj).curpos = mask;
                        W.scrollmap_internal(mask) = kobj;
                    end
                case {'chgfigpos' 'remove' 'add'}
                    % need to re-build the full map -> postpone until it is
                    % actually needed!
                    W.scrollmap_internal = [];
                case 'chgpos'
                    % need to re-build the full map... only if the object
                    % is active!
                    if W.objects(kobj).doscroll
                        W.scrollmap_internal = []; 
                    end
                case 'set'
                    % set current size
                    W.cursize = siz;
                    % build the full map
                    mask0 = false(siz);
                    curmap = ones(siz(1),siz(2)); % 1 refers to first object, i.e. the figure
                    for kobj=2:nobj % start at 2, first element is the figure!
                        sk = W.objects(kobj);
                        hobj = sk.hobj;
                        if sk.doscroll && ishandle(hobj)
                            pos = round(fn_pixelpos(hobj,'recursive'));
                            pos = fn_minmax('axi',[pos(1) pos(1)+pos(3) pos(2) pos(2)+pos(4)],[1 siz(1) 1 siz(2)]);
                            mask = mask0; mask(pos(1):pos(2),pos(3):pos(4)) = true;
                            W.objects(kobj).curpos = mask;
                            curmap(mask) = kobj;
                        else
                            W.objects(kobj).curpos = []; % in case object will be put back later, its mask will need to be recalculated
                        end
                    end
                    W.scrollmap_internal = curmap;
            end
        end
    end
    
    % Scroll wheel action
    methods
        function scrollwheelaction(W,e)
            pt = get(W.hf,'currentpoint');
            if all(pt>=1 & pt<=size(W.scrollmap))
                hobj = W.objects(W.scrollmap(pt(1),pt(2))).hobj;
            else
                % on Windows, the window can be active while the mouse is
                % outside of it
                hobj = W.hf;
            end
            kobj = find([W.objects.hobj]==hobj);
            if isempty(kobj), error programming, end
            if ~W.objects(kobj).doscroll || isempty(W.objects(kobj).callback), return, end
            if ~W.busy
                % execute the action
                W.busy = true;
                c = onCleanup(@()set(W,'busy',false));
                nscroll = W.scrollcount + e.VerticalScrollCount;
                W.scrollcount = 0;
                fun = W.objects(kobj).callback;
                args = regexp(char(fun),'^@\(([\w,])*\)','tokens');
                narg = 1+sum(args{1}{1}==',');
                switch narg
                    case 1
                        W.objects(kobj).callback(nscroll);
                    case 2
                        W.objects(kobj).callback(nscroll,W.activekeys);
                    otherwise
                        error 'callback must have one or two arguments'
                end
            else
                % cancel the action, but remember the number of scrolls
                W.scrollcount = W.scrollcount + e.VerticalScrollCount;
            end
        end
    end
    
    % Keyboard monitoring
    methods
        function keyboardmonitor(W,e,dir)
            if ~fn_ismemberstr(e.Key,{'shift' 'control'}), return, end
            switch dir
                case 'press'
                    W.activekeys = union(W.activekeys,e.Key);
                case 'release'
                    W.activekeys = setdiff(W.activekeys,e.Key);
                otherwise
                    error 'wrong press/release flag'
            end
        end
    end
end




