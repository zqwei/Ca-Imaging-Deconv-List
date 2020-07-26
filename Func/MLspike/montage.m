classdef montage < interface
    % function M = montage([fname]
    % function M = montage(images[,names or struct])
    % GUI program for manual alignment of a large set of images
    
    % Thomas Deneux
    % Copyright 2015-2017

    properties
        im = immodel('empty');
        lastim = cell(1,0);     % memory of previous states (including current one) for undo and re-do
        numredo = 0;            % number of re-do operations that are possible
        X
        filterset = struct('filter',cell(1,0),'control',cell(1,0));
        context
        showmarks = true;
        motionfactor = 1;
        flashtimer
        flashphase
    end
    properties (SetObservable = true)
        showinactive = true;
        scrollwheel = 'zoom'; % 'zoom' or 'alpha'
    end
    
    % Init
    methods
        function M = montage(varargin)
            hf = figure('name','montage','integerhandle','off');
            M = M@interface(hf,'Montage');
            set(hf,'resize','on')
            init_context(M)
            init_grob(M)
            interface_end(M)
            init_control(M)
            init_filters(M)
            %M.loadimages(evalin('base','a'))
            if nargin>=1
                a = varargin{1};
                if ischar(a)
                    loaddata(M,varargin{:})
                elseif isnumeric(a) || iscell(a) || isstruct(a)
                    loadimages(M,varargin{:})
                else 
                    error argument
                end
            else
                load_example(M)
            end
        end
        function init_grob(M)
            M.grob.ha = axes( ...
                'buttondownfcn',@(u,e)action(M,'axes'));
            fn_pixelsizelistener(M.grob.ha,@(u,e)M.show('chgratio'))
            colormap(M.grob.ha,gray(256))
            M.grob.x = uipanel;
            fn_pixelsizelistener(M.grob.x,@(u,e)M.init_control)
            fn_pixelsizelistener(M.grob.x,@(u,e)M.init_filters)
            fn_scrollwheelregister(M.hf,@(n)scrollaxis(M,n))
            set(gcf,'KeyPressFcn',@(u,e)keypress(M,'press',e),'KeyReleaseFcn',@(u,e)keypress(M,'release',e))
            M.grob.list = uicontrol('style','listbox','max',2,'units','normalized', ...
                'callback',@(u,e)M.action('listselect','context'), ...
                'uicontextmenu',M.context);
            M.grob.xfilter = uipanel;
        end
        function init_menus(M)
            init_menus@interface(M)
            % content
            m = M.menus.interface;
            uimenu(m,'label','add images from files','separator','on',...
                'callback',@(u,e)loadimages(M,'file'))
            uimenu(m,'label','add images from base workspace',...
                'callback',@(u,e)loadimages(M,'matlab'))
            uimenu(m,'label','erase',...
                'callback',@(u,e)erase(M))
            % load/save
            uimenu(m,'label','Open...','separator','on',...
                'callback',@(u,e)loaddata(M))
            uimenu(m,'label','Save as...',...
                'callback',@(u,e)savedata(M))
            % reset display
            uimenu(m,'label','Reset display','separator','on', ...
                'callback',@(u,e)show(M,'reset'))
            % undo/redo
            uimenu(m,'label','undo last change','separator','on', ...
                'callback',@(u,e)undo(M))
            uimenu(m,'label','re-do last change', ...
                'callback',@(u,e)redo(M))
            % show marks
            uimenu(m,'label','Show marks','separator','on','Checked',fn_switch(M.showmarks), ...
                'callback',@(u,e)set(M,'showmarks',~M.showmarks))
            % Grid menu
            gridMenu(M)
            % Scroll wheel menu
            scrollMenu(M)
        end
        function scrollMenu(M)
            M.menus.scroll = uimenu(M.hf,'label','Scroll Wheel');
            m = M.menus.scroll;
            fn_propcontrol(M,'scrollwheel', ...
                {'menugroup' {'zoom' 'alpha'} {'Zoom' 'Transparency of selection'}}, ...
                {'parent' m});
        end
        function init_control(M)
            s = struct( ...
                'parameters',   {'' 'label'}, ...
                'bin__images',  {1  'double'}, ...
                'alpha',    {.7     'slider 0 1'}, ...
                'white',    {0      'slider 0 1'}, ...
                'clip',     {'fit'  'char'}, ...
                'checkerboard',     {[]     'xstepper 1 3 Inf'}, ...
                'checkerinvert',    {false  'logical < checkerboard'}, ...
                'flash',            {[]     'xlogslider -1 .5 [0]'}, ...
                'flashsharp',       {.5     'slider 0 1 < flash'});
            M.X = fn_control(s,@(s)updatePar(M),M.grob.x);
        end
        function init_context(M)
            if isempty(M.context)
                m = uicontextmenu('parent',M.hf);
                M.context = m;
            else
                m = M.context;
                delete(get(m,'children'))
            end
            uimenu(m,'label','select all','callback',@(u,e)selectimages(M,1:length(M.im)))
            uimenu(m,'label','move to top','separator','on','callback',@(u,e)action(M,'stacktop','context'))
            uimenu(m,'label','move to bottom','callback',@(u,e)action(M,'stackbottom','context'))
            uimenu(m,'label','rename','separator','on','callback',@(u,e)action(M,'rename','context'))
            uimenu(m,'label','set scale','separator','on','callback',@(u,e)action(M,'setscale','context'))
            uimenu(m,'label','no rotation','callback',@(u,e)action(M,'norotation','context'))
            %uimenu(m,'label','not transparent','callback',@(u,e)action(M,'noalpha','context'))
            uimenu(m,'label','set as background','callback',@(u,e)action(M,'setbackground','context'))
            uimenu(m,'label','remove background','callback',@(u,e)action(M,'removebackground','context'))
            uimenu(m,'label','group','separator','on','callback',@(u,e)action(M,'group','context'))
            uimenu(m,'label','ungroup','callback',@(u,e)action(M,'ungroup','context'))
            %uimenu(m,'label','remove from group','callback',@(u,e)action(M,'exitgroup','context'))
            uimenu(m,'label','new filter','separator','on','callback',@(u,e)action(M,'newfilter','context'))
            uimenu(m,'label','remove filter','callback',@(u,e)action(M,'rmfilter','context'))
            uimenu(m,'label','show','separator','on','callback',@(u,e)action(M,'show','context'))
            uimenu(m,'label','hide','callback',@(u,e)action(M,'hide','context'))
            fn_propcontrol(M,'showinactive','menu','parent',m,'label','show hidden in list');
            uimenu(m,'label','discard','callback',@(u,e)action(M,'discard','context'))
        end
    end
    
    % Display
    methods
        function show(M,varargin)
            % function show(M[,idx][,flag])
            ha = M.grob.ha;
            % no image?
            if isempty(M.im)
                cla(ha), delete(get(ha,'children'))
                set(ha,'xtick',[],'ytick',[],'box','on')
                set(M.grob.list,'string',{},'value',[])
                return
            end
            % input
            flag = '';
            idx = 1:length(M.im);
            for k=1:length(varargin)
                a = varargin{k};
                if ischar(a)
                    flag = a;
                elseif isnumeric(a)
                    idx = row(a);
                else
                    argument error
                end
            end
            % which action should be performed
            dozoomout = ismember(flag,{'reset' 'newimg'});
            doratio = dozoomout || strcmp(flag,{'chgratio'});
            doredraw = ismember(flag,{'reset' 'undo'});
            doimage = doredraw || ismember(flag,{'newimg' '' 'image'});
            doalpha = doimage || strcmp(flag,'alpha');
            docoord = doredraw || ismember(flag,{'newimg' '' 'move'});
            dorenum = strcmp(flag,'renum');
            doactive = doredraw || ismember(flag,{'active' 'activenofilter'});
            dolist = doactive || strcmp(flag,'newimg');
            % reset display
            if doredraw
                if ~isequal(idx,1:length(M.im)), error 'full redraw cannot be applied on only a subset of images', end
                delete(findobj(ha,'tag','montage'))
            end
            % loop on images
            xbin = M.X.bin__images; if xbin==0, xbin=1; end
            if nargin<3
                idx = 1:length(M.im);
            end
            for i=idx
                s = M.im(i);
                if ~s.active && ~doactive, continue, end
                doredraw = isempty(s.h) || ~all(ishandle(s.h));
                % compute
                if doimage || doalpha
                    % image
                    a = s.data;
                    if ismatrix(a)
                        a = uint8(fn_clip(a,M.X.clip,[0 255]));
                    elseif size(a,3)==4
                        % remove transparency channel
                        a(:,:,4) = [];
                    end
                    if xbin>1, a = uint8(fn_bin(a,xbin)); end
                    [ni nj ncol] = size(a); %#ok<ASGLU>
                    % transparency
                    outmask = any(isnan(a),3);
                    if (~isempty(s.transparentcolor) || any(outmask(:))) && ~s.isbackground
                        for k=1:size(s.transparentcolor,1)
                            col = third(s.transparentcolor(k,:));
                            outmask = outmask | all(bsxfun(@eq,s.data,col),3);
                        end
                        alpha = outmask*M.X.white + ~outmask*M.X.alpha;
                    else
                        alpha = [];
                    end
                    % add checkerboard transparency
                    if ~isempty(M.X.checkerboard) && s.selected && ~s.isbackground
                        squareside = round(min(ni,nj)/M.X.checkerboard);
                        nsqx = ceil(ni/squareside); nsqy = ceil(nj/squareside);
                        checker = mod(fn_add(column(1:nsqx),row(1:nsqy)),2);
                        checker = fn_enlarge(checker,[nsqx nsqy]*squareside);
                        checker = checker(1:ni,1:nj);
                        if M.X.checkerinvert, checker = 1-checker; end
                        if isempty(alpha)
                            alpha = checker*M.X.alpha;
                        else
                            alpha = checker*alpha;
                        end
                    end
                else
                    [ni nj ncol] = size(s.data); %#ok<ASGLU>
                    ni = floor(ni/xbin);
                    nj = floor(nj/xbin);
                end
                if docoord
                    ngrid = 2;
                    [ii jj] = ndgrid(linspace(1,ni,ngrid),linspace(1,nj,ngrid));
                    ij = [ones(1,ngrid*ngrid); row(ii); row(jj)];
                    T1 = [1 0 0; [-(ni+1)/2; -(nj+1)/2] eye(2)]; % set central pixel to zero
                    TSR = [[s.xc; s.yc] s.scale*xbin*[cos(s.rot) -sin(s.rot); sin(s.rot) cos(s.rot)]];
                    xy = (TSR*T1)*ij;
                    xx = reshape(xy(1,:),ngrid,ngrid); yy = reshape(xy(2,:),ngrid,ngrid);
                    zz = zeros(ngrid);
                    xyh = TSR*[1 1; [0; 0] [(ni+1)/2; 0]]; % handles: center, right side
                end
                % update display
                if doredraw
                    % image
                    M.im(i).h = gobjects;
                    M.im(i).h(1) = surface(xx,yy,zz,a,'parent',M.grob.ha, ...
                        'EdgeColor','none','FaceColor','texturemap','CDataMapping','direct', ...
                        'buttondownfcn',@(u,e)action(M,'select&move',i), ...
                        'uiContextMenu',M.context,'userdata',i,'tag','montage', ...
                        'visible',fn_switch(s.active));
                    if ~isempty(alpha)
                        set(M.im(i).h(1),'alphadata',alpha,'alphadatamapping','none','facealpha','texturemap')
                    else
                        set(M.im(i).h(1),'FaceAlpha',M.X.alpha)
                    end
                    M.im(i).h(2) = line(xyh(1,2),xyh(2,2),'parent',M.grob.ha, ...
                        'color','b','linestyle','none','marker','o', ...
                        'uiContextMenu',M.context,'userdata',i,'tag','montage', ...
                        'buttondownfcn',@(u,e)action(M,'select&rotate',i), ...
                        'visible',fn_switch(s.active && M.showmarks));
                    M.im(i).h(3) = text(xyh(1,1),xyh(2,1),s.name,'parent',M.grob.ha, ...
                        'color','b', ...
                        'buttondownfcn',@(u,e)action(M,'select&move',i), ...
                        'uiContextMenu',M.context,'userdata',i,'tag','montage', ...
                        'horizontalalignment','center','verticalalignment','middle','interpreter','none', ...
                        'visible',fn_switch(s.active && M.showmarks));
                    if s.isbackground
                        set(M.im(i).h,'HitTest','off')
                        uistack(fliplr(M.im(i).h),'bottom')
                    end
                else
                    if doimage, set(M.im(i).h(1),'cdata',a), end
                    if doalpha
                        if ~isempty(alpha)
                            set(M.im(i).h(1),'alphadata',alpha,'alphadatamapping','none','facealpha','texturemap')
                        elseif s.isbackground
                            set(M.im(i).h(1),'FaceAlpha',1)
                        else
                            set(M.im(i).h(1),'FaceAlpha',M.X.alpha)
                        end
                    end
                    if docoord
                        % image
                        set(M.im(i).h(1),'xdata',xx,'ydata',yy)
                        % handles
                        set(M.im(i).h(2),'xdata',xyh(1,2),'ydata',xyh(2,2))
                        set(M.im(i).h(3),'pos',[xyh(1,1) xyh(2,1)])
                    end
                    if dorenum, set(M.im(i).h(1),'userdata',i), end
                    if doactive
                        set(M.im(i).h(1),'visible',fn_switch(s.active))
                        set(M.im(i).h(2:end),'visible',fn_switch(s.active && M.showmarks))
                    end
                    set(M.im(i).h,'hittest',fn_switch(~s.isbackground))
                    if s.isbackground
                        uistack(fliplr(M.im(i).h),'bottom')
                    end
                end
            end
            % general actions (most of them occur only on reset)
            if dozoomout
                % reset zoom
                fn_axis(ha,'tight',1.02)
            end
            if doratio
                % maintain ratio
                ax = axis(ha);
                pp = fn_pixelsize(ha);
                r = pp(2)/pp(1);
                rc = (ax(4)-ax(3))/(ax(2)-ax(1));
                if rc>r
                    % need to expand in x
                    ax(1:2) = mean(ax(1:2)) + [-.5 .5]*diff(ax(3:4))/r;
                else
                    % need to expand in y
                    ax(3:4) = mean(ax(3:4)) + [-.5 .5]*diff(ax(1:2))*r;
                end
                axis(ha,ax)
            end
            if doredraw
                % clean axes
                set(ha,'xtick',[],'ytick',[],'box','on','ydir','reverse')
                set(M.grob.list,'value',[])
            end
            % update list of images
            if dolist
                showList(M)
            end
            % update visibility filters
            if doactive && ~strcmp(flag,'activenofilter')
                updateFilters(M)
            end
        end 
        function stackImages(M,i,flag)
            % Change order of images, while preserving order of other
            % elements (e.g. grid, background image)
            i([M.im(i).isbackground]) = [];         % make sure background image is not included
            hi = row(fliplr(cat(1,M.im(i).h)));     % images and handles to be moved
            cc = row(get(M.grob.ha,'children'));    % all children
            hh = [M.im(~[M.im.isbackground]).h];    % all images and handles, excluding background image
            hj = setdiff(hh,hi);                    % images and handles other than those to be moved
            hj = intersect(cc,hj,'stable');         % preserve the order in cc
            switch flag
                case 'top'
                    hh = [hi hj];
                case 'bottom'
                    hh = [hj hi];
            end
            sep = find(cc==hh(1));                  % separate between children appearing before and after one random image
            c1 = setdiff(cc(1:sep),hh,'stable');    % other children appearing before
            c2 = setdiff(cc(sep:end),hh,'stable');  % other children appearing after
            set(M.grob.ha,'children',[c1 hh c2])
        end
        function showList(M)
            allnames = {M.im.name};
            for i=1:length(allnames)
                s = M.im(i);
                if ~s.active, allnames{i} = ['<' allnames{i} '>']; end
                if ~isempty(s.group), allnames{i} = [s.group ' - ' allnames{i}]; end
                allnames{i} = [num2str(i,'[%i] ') allnames{i}];
            end
            if ~M.showinactive
                allnames(~[M.im.active]) = [];
            end
            curtop = get(M.grob.list,'ListboxTop');
            set(M.grob.list,'string',allnames)
            set(M.grob.list,'ListboxTop',min(curtop,length(allnames)))
        end
    end
    
    % Callbacks
    methods
        % changing display only
        function moveaxis(M)
            ha = M.grob.ha;
            p0 = get(M.hf,'currentpoint');
            curpointer = get(M.hf,'pointer');
            set(M.hf,'pointer','hand')
            p0 = get(ha,'currentpoint'); p0 = p0(1,1:2);
            ax = axis(ha);
            fn_buttonmotion(@chgaxis,M.hf)
            function chgaxis
                p = get(ha,'currentpoint'); p = p(1,1:2);
                movax = p0-p;
                %                 sidedist = M.oldaxis - M.axis;
                %                 movax = max(sidedist(:,1),min(sidedist(:,2),movax));
                ax = ax + movax([1 1 2 2]);
                axis(ha,ax)
            end
            set(M.hf,'pointer',curpointer)
        end
        function scrollaxis(M,n)
            switch M.scrollwheel
                case 'zoom'
                    n=n/4*M.motionfactor;
                    ha = M.grob.ha;
                    p = get(ha,'currentpoint'); p = p(1,[1 1 2 2]);
                    ax = axis(ha);
                    ax = p + (ax-p)*(1.2^n);
                    axis(ha,ax)
                case 'alpha'
                    idx = find([M.im.selected]);
                    if isempty(idx), return, end
                    hh = M.im(idx).h; h = hh(:,1);
                    alpha = get(h(1),'FaceAlpha'); 
                    if ~isscalar(alpha), alpha = M.X.alpha; end
                    alpha = fn_coerce(alpha-n/10,0,1);
                    set(h,'FaceAlpha',alpha)
            end
        end
        function idx = getSelection(M)
            idx = get(M.grob.list,'value');
            if ~M.showinactive
                active = find([M.im.active]);
                idx = active(idx);
            end
        end
        function selectimages(M,idx)
            % select in list
            idxlist = false(1,length(M.im));
            idxlist(idx) = true;
            if ~M.showinactive, idxlist(~[M.im.active]) = []; end
            set(M.grob.list,'value',find(idxlist))
            % mark images as selected
            oldidx = find([M.im.selected]);
            [M.im(oldidx).selected] = deal(false);
            [M.im(idx).selected] = deal(true);
            % update colors in display
            if M.showmarks
                h = cat(1,M.im.h);
                if ~isempty(h), set(h(:,2:3),'color','b'), end
                h = cat(1,M.im(idx).h);
                if ~isempty(h), set(h(:,2:3),'color','r'), end
            end
            % update previously and newly selected images (in case
            % something special occurs with selected one such as
            % checkerboard, alpha scrolling...)
            M.show(union(oldidx,idx),'image')
        end
        function set.showmarks(M,x)
            M.showmarks = x;
            M.show('active')
        end
        function updatePar(M)
            if any(ismember({'checkerboard' 'checkerinvert' 'clip' 'bin__images'},M.X.changedfields))
                M.show('image')
            elseif any(ismember({'alpha' 'white'},M.X.changedfields))
                M.show('alpha')
            end
            if ismember('flash',M.X.changedfields)
                M.flashimages()
            end
        end
        % changing content
        function keypress(M,flag,e)
            % update current motion factor, so it can be used for wheel
            % scrolling
            if ismember('control',e.Modifier)
                M.motionfactor = 1/4;
            elseif ismember('shift',e.Modifier)
                M.motionfactor = 4;
            else
                M.motionfactor = 1;
            end                
            if strcmp(flag,'release'), return, end
            % undo/redo
            if ismember('control',e.Modifier) && strcmp(e.Key,'z')
                if ismember('shift',e.Modifier)
                    redo(M)
                else
                    undo(M)
                end
                return
            end
            % extend to group?
            i = find([M.im.selected]);
            if isempty(i), return, end
            group = unique({M.im(i).group});
            if ~isscalar(group)
                waitfor(errordlg('all images should belong to the same group when moving'))
                return
            end
            dogroup = ~strcmp(group,'') && ~ismember(flag,{'exitgroup'});
            iorig = i(1);
            if dogroup
                i = find(strcmp({M.im.group},group));
            end
            % action
            if ~any([M.im(i).active]), return, end
            ax = axis(M.grob.ha);
            tstep = 1/1000 * mean(diff(ax([1 3; 2 4]))) * M.motionfactor;
            rstep = 1/10 * pi/180 * M.motionfactor;
            zstep = 1.001 ^ M.motionfactor;
            sorig = M.im(iorig); s = M.im(i);
            switch(e.Key)
                case 'leftarrow'
                    [M.im(i).xc] = dealc([M.im(i).xc]-tstep);
                case 'rightarrow'
                    [M.im(i).xc] = dealc([M.im(i).xc]+tstep);
                case 'uparrow'
                    [M.im(i).yc] = dealc([M.im(i).yc]-tstep);
                case 'downarrow'
                    [M.im(i).yc] = dealc([M.im(i).yc]+tstep);
                case {'multiply' 'divide'}
                    drot = fn_switch(e.Key,'multiply',rstep,'divide',-rstep);
                    [xcorig ycorig] = deal(sorig.xc,sorig.yc);
                    [xc0 yc0] = deal([s.xc],[s.yc]);
                    u0 = [xc0-xcorig; yc0-ycorig];
                    R = [cos(drot) -sin(drot); sin(drot) cos(drot)];
                    u = R*u0;
                    for ki=1:length(i)
                        ik = i(ki);
                        M.im(ik).xc = xcorig + u(1,ki);
                        M.im(ik).yc = ycorig + u(2,ki);
                        M.im(ik).rot = s(ki).rot + drot;
                    end
                case {'add' 'subtract'}
                    scalefact = fn_switch(e.Key,'add',zstep,'subtract',1/zstep);
                    [xcorig ycorig] = deal(sorig.xc,sorig.yc);
                    [xc0 yc0] = deal([s.xc],[s.yc]);
                    u0 = [xc0-xcorig; yc0-ycorig];
                    u = scalefact*u0;
                    for ki=1:length(i)
                        ik = i(ki);
                        M.im(ik).xc = xcorig + u(1,ki);
                        M.im(ik).yc = ycorig + u(2,ki);
                        M.im(ik).scale = s(ki).scale * scalefact;
                    end
                case 'pagedown'
                    M.stackImages(i,'bottom')
                    return
                case 'pageup'
                    M.stackImages(i,'top')
                    return
                otherwise
                    %disp(e.Key)
                    return
            end
            M.show('move',i)
            M.storeCurrent()
        end
        function action(M,flag,i)
            % handle mouse actions according to which button is pressed
            if ismember(flag,{'axes' 'select&move' 'select&rotate'}) 
                seltype = get(M.hf,'selectionType');
                switch seltype
                    case 'alt'
                        if strcmp(flag,'select&move')
                            flag = 'select';
                        else
                            return
                        end
                    case 'open'
                        return
                    case 'extend'
                        if ismember(flag,{'axes' 'select&move'}), moveaxis(M), end
                        return
                    case 'normal'
                        if strcmp(flag,'axes')
                            idx = find([M.im.selected]);
                            if ~isempty(idx)
                                M.selectimages([])
                                M.show(idx,'image')
                            end
                            return
                        end
                end
                iorig = i; % remember which image was originally selected
            else
                iorig = [];
            end
            % which image(s)
            % (no image)
            if isempty(i), disp 'no image selected', return, end
            % (selection in list)
            idxsel = M.getSelection();
            if strcmp(i,'context')
                i = idxsel;
                if isempty(i), return, end
            elseif ismember(flag,{'select' 'select&move' 'select&rotate'}) && isempty(M.im(i).group) && any(i==idxsel)
                i = idxsel;                
            end
            % (extend to group?)
            selectimages(M,i)
            if ismember(flag,{'ungroup' 'select&move' 'select&rotate' 'norotation' 'setscale'})
                group = unique({M.im(i).group});
                if strcmp(flag,'norotation') && (~isscalar(group) || (~strcmp(group,'') && ~isscalar(i)))
                    waitfor(errordlg('when applying ''norotation'', either all images should belong to no group, or a only one image should be selected'))
                    return
                elseif ~isscalar(group)
                    waitfor(errordlg('selected images must all be part of no group, or of the same group'))
                    return
                end
                dogroup = ~strcmp(group,'') && ~ismember(flag,{'exitgroup'});
                if dogroup
                    if strcmp(flag,'norotation'), iorig = i; end
                    i = find(strcmp({M.im.group},group));
                end
            end
            % perform action
            % (remember current state and prepare flag for whether to store
            % it)
            % (common to several actions: stack to top)
            if ismember(flag,{'show' 'listselect' 'stacktop' 'select&move' 'select&rotate'})
                M.stackImages([iorig setdiff(i,iorig)],'top')
            end
            % (list select + double-click -> toggle visibility)
            if strcmp(flag,'listselect') && isscalar(i) && strcmp(get(M.hf,'selectionType'),'open')
                flag = fn_switch(M.im(i).active,'hide','show');
            end
            % (other actions)
            switch flag
                case {'stacktop' 'listselect'}
                    % no more action
                case 'stackbottom'
                    M.stackImages(i,'bottom')
                case {'select&move' 'select&rotate'}
                    curpointer = get(M.hf,'pointer');
                    set(M.hf,'pointer','hand')
                    ha = M.grob.ha;
                    p0 = get(ha,'currentpoint'); p0 = p0(1,1:2);
                    s = M.im(i);
                    switch flag
                        case 'select&move'
                            [xc0 yc0] = deal([s.xc],[s.yc]);
                        case 'select&rotate'
                            sorig = M.im(iorig);
                            [xcorig ycorig rotorig] = deal(sorig.xc,sorig.yc,sorig.rot);                            
                            [xc0 yc0 rot0] = deal([s.xc],[s.yc],[s.rot]);
                            u0 = [xc0-xcorig; yc0-ycorig];
                    end
                    moved = fn_buttonmotion(@mov,M.hf);
                    if isempty(moved)
                        % select back single image
                        M.selectimages(iorig)
                    end
                    set(M.hf,'pointer',curpointer)
                case 'rename'                    
                    answer = inputdlg(repmat({'name:'},1,length(i)),'Rename images',1,{M.im(i).name});
                    if isempty(answer), return, end
                    [M.im(i).name] = deal(answer{:});
                    showList(M)
                case 'norotation'
                    if dogroup
                        s = M.im(i);
                        sorig = M.im(iorig);
                        [xcorig ycorig rotorig] = deal(sorig.xc,sorig.yc,sorig.rot);
                        [xc0 yc0 rot0] = deal([s.xc],[s.yc],[s.rot]);
                        u0 = [xc0-xcorig; yc0-ycorig];
                        drot = -rotorig;
                        R = [cos(drot) -sin(drot); sin(drot) cos(drot)];
                        u = R*u0;
                        for k=1:length(i)
                            j = i(k);
                            M.im(j).xc = xcorig + u(1,k);
                            M.im(j).yc = ycorig + u(2,k);
                            M.im(j).rot = rot0(k)+drot;
                        end
                    else
                        [M.im(i).rot] = deal(0);
                    end
                    M.show('move',i)
                case 'setscale'
                    try
                        x = evalin('base',fn_input('scale',num2str(M.im(i(1)).scale)));
                    catch
                        return
                    end
                    if ~(isscalar(x) && isnumeric(x)), return, end
                    [M.im(i).scale] = deal(x);
                    M.show('move',i)
                case 'noalpha'
                    for s = M.im(i)
                        alpha = all(~isnan(s.data),3);
                        if all(alpha(:))
                            set(s.h(1),'facealpha',1)
                        else
                            set(s.h(1),'alphadata',alpha,'alphadatamapping','none','facealpha','texturemap')
                        end
                    end
                case 'setbackground'
                    if ~isscalar(i)
                        errordlg 'only one image can be set as background'
                        return
                    end
                    [M.im.isbackground] = deal(false);
                    M.im(i).isbackground = true;
                    M.show()
                case 'removebackground'
                    [M.im.isbackground] = deal(false);
                    M.show()
                case 'group'
                    % group images
                    % (suggest a group name)
                    groups = unique({M.im.group});
                    tokens = regexp(groups,'^GROUP (\d+)$','tokens');   % length(groups) cell array of cell arrays of cell arrays!
                    tokens = [tokens{:}]; num = str2double([tokens{:}]); % number already taken
                    kgroup = 1; while ismember(kgroup,num), kgroup = kgroup+1; end
                    defaultname = ['GROUP ' num2str(kgroup)];
                    answer = inputdlg('Group name:','montage',1,{defaultname});
                    % (assign group)
                    [M.im(i).group] = deal(answer{1});
                    % (update list display)
                    M.showList()
                case {'ungroup' 'exitgroup'}
                    % (un-assign group)
                    [M.im(i).group] = deal('');
                    % (update list display)
                    M.showList()
                case 'discard'
                    hh = cat(1,M.im(i).h);
                    delete(hh(:))
                    M.im(i) = [];
                    % (update display)
                    M.showList()
                    M.selectimages([])
                    M.updateFilters()
                    if isempty(M.im), M.show(), end
                case {'show' 'hide'}
                    val = fn_switch(flag,'show',true,'hide',false);
                    [M.im(i).active] = deal(val);
                    M.show('active',i)
                    if strcmp(flag,'show') && ~M.showinactive, selectimages(M,[]), end
                    %if strcmp(flag,'show'), selectimages(M,i), end
                case 'newfilter'
                    % filter
                    % (suggest a filter name)
                    filters = unique({M.im.filter});
                    tokens = regexp(filters,'^FILTER (\d+)$','tokens');   % length(groups) cell array of cell arrays of cell arrays!
                    tokens = [tokens{:}]; num = str2double([tokens{:}]); % number already taken
                    kfilt = 1; while ismember(kfilt,num), kfilt = kfilt+1; end
                    defaultname = ['FILTER ' num2str(kfilt)];
                    answer = inputdlg('Filter name:','montage',1,{defaultname});
                    if isempty(answer), return, end
                    % (assign group)
                    [M.im(i).filter] = deal(answer{1});
                    % (update filters display)
                    M.init_filters()
                case 'rmfilter'
                    % (select images)
                    filter = unique({M.im(i).filter});
                    if ~isscalar(filter)
                        waitfor(errordlg('selected images must all be part of the same filter'))
                        return
                    end
                    i = strcmp({M.im.filter},filter);
                    % (unset filter)
                    [M.im(i).filter] = deal('');
                    % (update filters display)
                    M.init_filters()
            end
            
            % Store current state
            M.storeCurrent()
            
            function moved = mov
                p = get(ha,'currentpoint'); p = p(1,1:2);
                switch flag
                    case 'select&move'
                        d = p-p0;
                        for ki=1:length(i)
                            ik = i(ki);
                            M.im(ik).xc = xc0(ki)+d(1);
                            M.im(ik).yc = yc0(ki)+d(2);
                        end
                    case 'select&rotate'
                        drot = atan2(p(2)-ycorig,p(1)-xcorig) - rotorig;
                        R = [cos(drot) -sin(drot); sin(drot) cos(drot)];
                        u = R*u0;
                        for ki=1:length(i)
                            ik = i(ki);
                            M.im(ik).xc = xcorig + u(1,ki);
                            M.im(ik).yc = ycorig + u(2,ki);
                            M.im(ik).rot = rot0(ki)+drot;
                        end
                end
                M.show('move',i)
                moved = true;
            end
        end
    end
    
    % Visibility filters
    methods
        function init_filters(M)
            hp = M.grob.xfilter;
            delete(get(hp,'children'))
            filters = setdiff(unique({M.im.filter},'stable'),'','stable');
            nfilt = length(filters);
            [W H] = fn_pixelsize(hp);
            h = 15; dy = 5; ystep = h+dy; 
            dx = 5; w = W-2*dx;    
            uicontrol('parent',hp,'style','text', ...
                'string','filters','pos',[dx H-ystep w h], ...
                'backgroundcolor',[1 1 1]*.6)
            for i=1:nfilt
                u = uicontrol('parent',hp,'style','checkbox', ...
                    'string',filters{i},'pos',[dx H-(i+1)*ystep w h], ...
                    'callback',@(u,e)doFilter(M,filters{i},u));
                M.filterset(i) = struct( ...
                    'filter',   filters{i}, ...
                    'control',  u);
            end
            updateFilters(M)
        end
        function doFilter(M,filter,u)
            set(u,'foregroundcolor','k')
            idx = find(strcmp({M.im.filter},filter));
            val = get(u,'value');
            [M.im(idx).active] = deal(val);
            M.show('activenofilter',idx) % 'activenofilter' flag indicates that visibility should be changed, but filters do not need to be updated (avoid inifinite loops!)
            if val
                M.selectimages(idx)
                M.stackImages(idx,'top')
            elseif ~M.showinactive
                M.selectimages([])
            end
        end
        function updateFilters(M)
            for i=1:length(M.filterset)
                s = M.filterset(i);
                filter = s.filter;
                idx = find(strcmp({M.im.filter},filter));
                if isempty(idx), return, end
                val = [M.im(idx).active];
                if all(val) || all(~val)
                    set(s.control,'foregroundcolor','k','value',val(1))
                else
                    set(s.control,'foregroundcolor',[1 1 1]*.7,'value',0)
                end
            end
        end
        function set.showinactive(M,b)
            M.selectimages([])
            M.showinactive = b;
            M.showList()
        end
    end
    
    % Dispatch
    methods
        function gridMenu(M)
            M.menus.grid = uimenu(M.hf,'label','Dispatch');
            m = M.menus.grid;
            s = struct;
            %s.grid = uimenu(m,'label','display grid','callback',@(u,e)setGrid(M,'toggle'));
            s.dispatch = uimenu(m,'label','dispatch mode','checked',fn_switch(~isempty([M.im.dispatch])), ...
                'callback',@(u,e)dispatch(M,'toggle'));
            uimenu(m,'label','stack grid top','callback',@(u,e)uistack(findall(M.grob.ha,'tag','dispatch_lines'),'top'))
            M.menus.items.grid = s;
        end
        function dispatch(M,val)
            % check and update control
            u = M.menus.items.grid.dispatch;
            if strcmp(val,'toggle'), val = fn_switch(get(u,'checked'),'toggle'); end
            set(u,'checked',val)
            
            % go
            ha = M.grob.ha;
            switch val
                case 'on'
                    % are we sure no image is under dispatch already?
                    shift = [M.im.dispatch];
                    if ~isempty(shift)
                        answer = inputdlg('At least some image(s) seem to be under dispatch already. Continue?','montage', ...
                            'Continue, ignore current dispatch info','Cancel','Continue, ignore current dispatch info');
                        if ~strcmp(answer,'Continue, ignore current dispatch info')
                            return
                        end
                        [M.im.dispatch] = deal([]);
                    end
                    delete(findall(ha,'tag','dispatch_lines'))
                    % total display extent
                    ax = axis(ha);
                    axis(ha,'tight'), extent = axis(ha); 
                    axis(ha,ax)
                    % divide into between 6 and 12 sections
                    W = diff(extent(1:2)); H = diff(extent(3:4));
                    spacing = 2^floor(log2(W/6));
                    xdiv = ceil(W/spacing/2)*2; % xdiv and ydiv are even
                    ydiv = ceil(H/spacing/2)*2;
                    xsep = xdiv*spacing;
                    ysep = ydiv*spacing;
                    % dispatch
                    [groups, ~, ic] = unique({M.im.group},'stable');
                    ngroup = length(groups);
                    ncol = round(sqrt(ngroup)*1.3);
                    nrow = ceil(ngroup/ncol);
                    shift = zeros(2,length(M.im));
                    for kgroup=1:ngroup
                        idx = (ic==kgroup);
                        [kcol krow] = ind2sub([ncol nrow],kgroup);
                        shift(1,idx) = (kcol-1)*xsep;
                        shift(2,idx) = (krow-1)*ysep;
                    end
                    [M.im.dispatch] = dealc(num2cell(shift,1));
                    [M.im.xc] = dealc([M.im.xc]+shift(1,:));
                    [M.im.yc] = dealc([M.im.yc]+shift(2,:));
                    % draw grid                    
                    xx = (floor(extent(1)/spacing) + (0:xdiv*ncol))*spacing;
                    yy = (floor(extent(3)/spacing) + (0:ydiv*nrow))*spacing;
                    axis(ha,[xx([1 end]) yy([1 end])])
                    hl = fn_lines(xx,yy,ha,'color',[1 1 1]*.6,'tag','dispatch_lines','hittest','off');
                    set([hl{1}(1:xdiv/2:end) hl{2}(1:ydiv/2:end)],'color','k')
                    % update display of images
                    M.show('reset')
                case 'off'
                    % un-dispatch
                    for i=1:length(M.im)
                        s = M.im(i);
                        if ~isempty(s.dispatch)
                            M.im(i).xc = s.xc - s.dispatch(1);
                            M.im(i).yc = s.yc - s.dispatch(2);
                            M.im(i).dispatch = [];
                        end
                    end
                    % remove grid
                    delete(findall(ha,'tag','dispatch_lines'))
                    % update display
                    M.show('reset')
            end
            M.storeCurrent()
        end
    end
    
    % Flash images
    methods
        function flashimages(M)
            % Init timer
            if isempty(M.flashtimer)
                M.flashtimer = timer('TimerFcn',@(u,e)flashupdate(M),'ExecutionMode','FixedSpacing');
                M.flashphase = 0;
            end
            % Stop timer
            stop(M.flashtimer)
            if isempty(M.X.flash)
                M.show(find([M.im.selected])) %#ok<FNDSB>
                return
            end
            % Timer period
            set(M.flashtimer,'Period',.05)
            % Start timer
            start(M.flashtimer)
        end
        function flashupdate(M)
            % phase
            nphase = 20;
            M.flashphase = mod(M.flashphase+1*M.X.flash/nphase,1);
            % alpha
            alpha = cos(2*pi*M.flashphase);
            sharp = 1 / (1-M.X.flashsharp); % between 1 and +Inf
            alpha = (2/pi)*atan(tan((pi/2)*alpha)*sharp);
            if isnan(alpha), alpha = 0; end
            alpha = (1+alpha)/2;
            % update image(s) transparency
            hh = cat(1,M.im([M.im.selected]).h); h = hh(:,1);
            set(h,'FaceAlpha',alpha)
        end
    end
    
    % Undo
    methods
        function storeCurrent(M,flag)
            if nargin>=2 && strcmp(flag,'reset')
                M.lastim(:) = [];
                M.numredo = 0;
            end
            s = M.im;
            if ~isempty(s), [s.h] = deal([]); end % handles should not be stored
            if ~isempty(M.lastim) && isequal(M.lastim{end},s), return, end
            if M.numredo>0
                M.lastim(end-(0:M.numredo-1)) = [];
                M.numredo = 0;
            end
            test = [M.lastim {s}];
            maxmem = 100*2^20; % keep maximum 100MB of history
            while length(test)>2 && getfield(whos('test'),'bytes')>maxmem, test(1) = []; end % note that whos returns only an upper bound of the memory that is actually used
            M.lastim = test;     
            memoryFingerprint(M)
        end
        function undo(M)
            if M.numredo<length(M.lastim)-1
                M.numredo = M.numredo+1;
                M.im = M.lastim{end-M.numredo};
                M.show('undo')
                memoryFingerprint(M)
            else
                beep
            end
        end
        function redo(M)
            if M.numredo>0
                M.numredo = M.numredo-1;
                M.im = M.lastim{end-M.numredo};
                M.show('undo')
                memoryFingerprint(M)
            else
                beep
            end
        end
        function memoryFingerprint(M)
            %             fprintf('memory: ')
            %             n = length(M.lastim);
            %             for i=1:n, fprintf([fn_hash(M.lastim{i},6) ' ']), end
            %             s = M.im; [s.h] = deal([]); db = dbstack;
            %             disp(['[' db(2).name ' ' fn_hash(s,6) ']'])
        end
    end
    
    % Load/save
    methods
        function load_example(M)
            v = load('clown');
            s(1) = struct('name','clown','data',fn_clip(v.X',v.map),'xc',200,'yc',100,'scale',1,'rot',0);
            v = load('chess');
            s(2) = struct('name','chess','data',fn_clip(v.X',v.map),'xc',0,'yc',0,'scale',1,'rot',pi/6);
            s(3) = struct('name','random','data',rand(10),'xc',100,'yc',-50,'scale',10,'rot',0);
            M.im = fn_structmerge(immodel,s);
            show(M,'reset')
            storeCurrent(M,'reset')
        end
        function loadimages(M,varargin)
            % loadimage(M,a[,names|structure])
            % loadimage(M,'file')
            % loadimage(M,'matlab')
            name = []; doconfirmnames = true; sim = []; domergestruct = false;
            if isnumeric(varargin{1}) || iscell(varargin{1})
                a = varargin{1};
                if ~iscell(a), a = {a}; end
                for i=1:length(a)
                    if ischar(a{i}), a{i}=fn_readimg(a{i}); end
                end
                if nargin>=3
                    if nargin>3, b = struct(varargin{2:end}); else b = varargin{2}; end
                    if isstruct(b)
                        sim = b;
                        if isfield(sim,'name'), name = {sim.name}; doconfirmnames = false; end
                        domergestruct = true;
                    else
                        name = varargin{2};
                        if ~iscell(name), name = {name}; end
                        doconfirmnames = false; 
                    end
                end
            else
                switch varargin{1}
                    case 'file'
                        f = fn_getfile;
                        if isequal(f,0), return, end
                        f = cellstr(f);
                        nim = length(f);
                        a = cell(1,nim);
                        for i=1:nim, a{i}=fn_readimg(f{i}); end
                        name = fn_fileparts(f,'base');
                    case 'matlab'
                        str = inputdlg('Enter cell array, or individual images separated by commas','Add images');
                        a = evalin('base',['{' str{1} '}']);
                        if isscalar(a) && (iscell(a{1}) || isstruct(a{1})), a = a{1}; end
                        if isstruct(a)
                            name = fieldnames(a);
                            a = struct2cell(a);
                        end
                end
            end
            nim = length(a);
            if doconfirmnames
                if isempty(name), name = repmat({''},1,nim); end
                name = inputdlg(repmat({'name:'},1,nim),'Add images',1,name);
            end
            model = immodel;
            nprev = length(M.im);
            for i=1:nim
                simi = struct('name',name{i},'data',a{i},'xc',0,'yc',0,'scale',1,'rot',0);
                if ~isempty(sim), simi = fn_structmerge(simi,sim(i)); end
                if domergestruct
                    simi = fn_structmerge(simi,b(i));
                end
                M.im(nprev+i) = fn_structmerge(model,simi);
            end
            % update display
            if nprev==0
                show(M,'reset')
            else
                show(M,'newimg',nprev+(1:nim))
            end
            init_filters(M)
            storeCurrent(M)
        end
        function erase(M)
            M.im(:)=[];
            show(M)
            storeCurrent(M)
        end
        function savedata(M,fname)
            if nargin<2
                fname = fn_savefile('*.mat'); 
                if isequal(fname,0), return, end
            end
            fname = fn_fileparts(fname,'noext');
            if isempty(regexp(fname,'_montage$', 'once')), fname = [fname '_montage']; end
            fname = [fname '.mat'];
            s = M.im;
            s = rmfield(s,'h');
            % cancel possible dispatch
            for i=1:length(s)
                if ~isempty(s(i).dispatch)
                    s(i).xc = s(i).xc - s(i).dispatch(1);
                    s(i).yc = s(i).yc - s(i).dispatch(2);
                    s(i).dispatch = [];
                end
            end
            % save
            c=fn_watch(M.hf);  %#ok<NASGU>
            fn_savevar(fname,s)
        end
        function loaddata(M,fname)
            if nargin<2, fname = fn_getfile('*.mat'); if ~fname, return, end, end
            % cancel possible dispatch
            dispatch(M,'off')
            % load
            x = fn_loadvar(fname);
            M.im = fn_structmerge(immodel,x);
            % update display
            show(M,'reset')
            init_filters(M)
            storeCurrent(M,'reset')
        end
    end
    
    % Output
    methods (Access='private')
        function [a dx] = getOutput(M,flag,dx)
            img = M.im(logical([M.im.active]));
            if nargin<3, dx=min([img.scale]); end
            n = length(img);
            % grid size
            range = NaN(n,4);
            for kim=1:n
                s = img(kim);
                [ni nj ~] = size(s.data);
                [ii jj] = ndgrid(linspace(1,ni,2),linspace(1,nj,2));
                ij = [ones(1,2*2); row(ii); row(jj)];
                T1 = [1 0 0; [-(ni+1)/2; -(nj+1)/2] eye(2)]; % set central pixel to zero
                TSR = [[s.xc; s.yc] s.scale*[cos(s.rot) -sin(s.rot); sin(s.rot) cos(s.rot)]];
                xy = (TSR*T1)*ij;
                range(kim,:) = [min(xy(1,:)) max(xy(1,:)) min(xy(2,:)) max(xy(2,:))];
            end
            % interpolate
            [xx yy] = ndgrid(min(range(:,1)):dx:max(range(:,2)),min(range(:,3)):dx:max(range(:,4)));
            [nx ny] = size(xx);
            xy = [ones(1,numel(xx)); row(xx); row(yy)];
            switch flag
                case 'align'
                    a = cell(1,n);
                case 'montage'
                    a = zeros(nx,ny,size(img(1).data,3));
                otherwise
                    error('unknown flag ''%s''',flag)
            end
            contrib = zeros(nx,ny);
            fn_progress('interpolate',n)
            for kim=1:n
                fn_progress(kim)
                s = img(kim);
                ak = double(s.data);
                [ni nj ncol] = size(ak);
                [ii jj] = ndgrid(1:ni,1:nj);
                T1 = [1 0 0; [-(ni+1)/2; -(nj+1)/2] eye(2)]; % set central pixel to zero
                TSR = [1 0 0; [s.xc; s.yc] s.scale*[cos(s.rot) -sin(s.rot); sin(s.rot) cos(s.rot)]]*T1;
                TSR1 = TSR^-1; TSR1(1,:)=[];
                ijinterp = TSR1*xy;
                ii1 = reshape(ijinterp(1,:),[nx ny]);
                jj1 = reshape(ijinterp(2,:),[nx ny]);
                % smooth
                if dx>s.scale
                    ak = fn_filt(ak,dx/s.scale,'lk',[1 2]);
                end
                % obtain contribution based on distance to sides
                if strcmp(flag,'montage')
                    %sigmacontrib = mean([range(:,2)-range(:,1); range(:,4)-range(:,3)])/2;
                    ck = exp(-20*((ii/ni-.5).^2+(jj/nj-.5).^2).^0.8);
                    % scale by contribution
                    ak = fn_mult(ak,ck);
                end
                % interpolate
                extrapval = fn_switch(flag,'align',NaN,'montage',0);
                if ncol==1
                    ak = interpn(ii,jj,ak,ii1,jj1,'linear',extrapval);
                else
                    ak = num2cell(ak,[1 2]);
                    for k=1:ncol
                        ak{k} = interpn(ii,jj,ak{k},ii1,jj1,'linear',extrapval);
                    end
                    ak = cat(3,ak{:});
                end
                % store
                switch flag
                    case 'align'
                        a{kim} = ak;
                    case 'montage'
                        ck = interpn(ii,jj,ck,ii1,jj1,'linear',0);
                        a = a+ak;
                        contrib = contrib+ck;
                end
            end
            if strcmp(flag,'montage')
                a = fn_div(a,contrib);
                a(isnan(a)) = 0;
            end
        end
    end
    methods
        function [a dx] = getAlignedImages(M,varargin)
            % function [a dx] = getAlignedImages(M,dx)
            [a dx] = getOutput(M,'align',varargin{:});
        end
        function [a dx] = getBigImage(M,varargin)
            % function [a dx] = getBigImage(M,dx)
            [a dx] = getOutput(M,'montage',varargin{:});
        end
    end
end

function im = immodel(emptyflag)

im=struct('name',[], ...
    'data',[],'transparentcolor',[], ...
    'xc',[],'yc',[],'scale',[],'rot',[], ...
    'h',[],'dispatch',[], ...
    'active',true,'selected',false,'isbackground',false, ...
    'group','','filter','');
if nargin>=1 && strcmp(emptyflag,'empty'), im(1)=[]; end

end
