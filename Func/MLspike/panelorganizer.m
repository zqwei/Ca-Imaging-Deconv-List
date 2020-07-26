classdef panelorganizer < hgsetget
    % function O = panelorganizer(hparent,'V|H',n[,dorelative[,xx]])
    % function hp = setSubPanel(O,idx,uipanel options...)
    % function O1 = setSubOrg(O,idx,'V|H',n[,dorelative[,xx]])
    %---
    % Divide a figure into resizeable panels
    
    % Thomas Deneux
    % Copyright 2015-2017

    properties (SetAccess='private')
        hobj
        splitmode
        children = struct('isset',cell(1,0),'isorg',[],'hobj',[],'org',[], ...
            'dorelative',[],'extent',[],'borders',[]); % note that extent will be maintained in pixel units
        borders = struct('left',[],'right',[],'top',[],'bottom',[]);
        szlistener
        minext = 20;
    end
    properties
        bordermode = 'twosides'; % 'twosides' or 'push'
    end
    properties (Dependent, SetAccess='private')
        nchildren
    end
    properties (Dependent)
        extents % extents are stored in pixel values, but can be set in relative values
    end
    
    % Constructor and split method
    methods
        function O = panelorganizer(hparent,splitmode,varargin)
            O.hobj = hparent;
            % if object is a figure, one can move the sides of the figure
            if strcmp(get(hparent,'type'),'figure')
                O.borders = struct('left',{{O 'figleft'}},'right',{{O 'figright'}}, ...
                    'top',{{O 'figtop'}},'bottom',{{O 'figbottom'}});
            end
            % split only after sides have been set
            O.split(splitmode,varargin{:});
            % listeners
            set(O.hobj,'DeleteFcn',@(u,e)delete(O))
            O.szlistener = fn_pixelsizelistener(O.hobj,@(u,e)set(O,'extents',[O.children.extent]));
        end
        function delete(O)
            if ~isvalid(O) && ~isprop(O,'szlistener'), return, end
            deleteValid(O.szlistener)
        end
        function split(O,mode,n,dorelative,xx)
            % input, checks
            mode = upper(mode);
            if ~ismember(mode,{'V' 'H'}), error 'incorrect mode flag', end
            ncur = O.nchildren;
            if nargin<3
                n = ncur;
            elseif any([O.children(n+1:ncur).isset])
                error 'cannot decrease number of sub-panels as some are non-empty'
            end
            if nargin<4
                dorelative = true(1,n);
            else
                dorelative = logical(dorelative);
            end
            if nargin<5
                [W H] = fn_pixelsize(O.hobj);
                x = fn_switch(mode,'H',W,'V',H);
                xx = ones(1,n)*(x/n);
            end
            % set
            O.splitmode = mode;
            if n<ncur
                delete([O.children(n+1:end).hobj])
                O.children(n+1:end) = [];
            elseif n>ncur
                % pre-allocate
                O.children(n).isset = [];
            end
            if n==0, return, end
            [O.children(ncur+1:n).isset] = deal(false);
            [O.children(ncur+1:n).isorg] = deal(false);
            [O.children.dorelative] = dealc(dorelative);
            % create children panels
            if strcmp(get(O.hobj,'type'),'figure')
                bgcol = get(O.hobj,'color');
            else
                bgcol = get(O.hobj,'backgroundcolor');
            end
            for i=ncur+1:n
                hp = uipanel('parent',O.hobj,'bordertype','none','backgroundcolor',bgcol);
                O.children(i).hobj = hp;
            end
            % convert extents to pixel units and update display
            O.extents = xx;
            % set borders, i.e. for each child, memorize what its 4 borders
            % are moving, and set callbacks when appropriate
            setBorders(O)
        end
    end
    
    % Get/Set
    methods
        function n = get.nchildren(O)
            n = length(O.children);
        end
        function set.bordermode(O,flag)
            if ~ismember(flag,{'twosides' 'push'})
                error 'incorrect value for ''bordermode'' property'
            end
            O.bordermode = flag;
        end
    end
    
    % Assign children
    methods
        function hp = setSubPanel(O,idx,varargin)
            if idx>O.nchildren, error 'index exceeds number of children', end
            if O.children(idx).isset, error('children %i is already set',idx), end
            c = O.children(idx);
            c.isset = true;
            c.isorg = false;
            O.children(idx) = c;
            % modify panel properties
            hp = c.hobj;
            set(hp,'bordertyp','line','borderwidth',1,'highlightcolor','k')
            set(hp,'deletefcn',@(u,e)delete(O)) % organizer cannot function normally if one of its child panels is deleted
            if ~isempty(varargin), set(hp,varargin{:}), end
        end
        function O1 = setSubOrg(O,idx,splitmode,varargin)
            if idx>O.nchildren, error 'index exceeds number of children', end
            if O.children(idx).isset, error('children %i is already set',idx), end
            c = O.children(idx);
            c.isset = true;
            c.isorg = true;
            O1 = panelorganizer(c.hobj,splitmode);
            O1.borders = c.borders;
            O1.split(splitmode,varargin{:}); % we must split only after borders have been assigned, otherwise children won't have all their borders properly defined
            c.org = O1;
            O.children(idx) = c;
        end
        function idx = addSub(O)
            idx = O.nchildren+1;
            % create child
            O.children(idx).isset = false;
            O.children(idx).isorg = false;
            O.children(idx).dorelative = true;
            % create child panel
            if strcmp(get(O.hobj,'type'),'figure')
                bgcol = get(O.hobj,'color');
            else
                bgcol = get(O.hobj,'backgroundcolor');
            end
            O.children(idx).hobj = uipanel('parent',O.hobj,'bordertype','none','backgroundcolor',bgcol);
            % update positions and borders
            xx = O.extents;
            if isempty(xx)
                O.extents = 1;
            else
                switch O.bordermode
                    case 'bothsides'
                        xx(idx) = mean(xx);
                        O.extents = xx;
                    case 'push'
                        O.pushExtent(idx,mean(xx))
                end
            end
            setBorders(O)
        end
        function [hp idx] = addSubPanel(O,varargin)
            idx = addSub(O);
            hp = setSubPanel(O,idx,varargin{:});
        end
        function O1 = addSubOrg(O,varargin)
            idx = addSub(O);
            O1 = setSubOrg(O,idx,varargin{:});
        end
        function idx = removeSubPanel(O,idx)
            % check
            if ~isvalid(O), return, end % occurs e.g. when closing figure
            if ishandle(idx) && ~strcmp(get(idx,'type'),'figure')
                idx = find([O.children.hobj]==idx,1);
                if isempty(idx), return, end % happens on reentrant call
            end
            if idx>O.nchildren, error 'index exceeds number of children', end
            if ~O.children(idx).isset, error 'no panel or sub-organization is set at this index', end
            % delete panel
            set(O.children(idx).hobj,'DeleteFcn','') % otherwise O will be deleted!
            delete(O.children(idx).hobj)
            % remove child
            O.children(idx) = [];
            % update positions and borders
            switch O.bordermode
                case 'bothsides'
                    O.extents = O.extents; % will readjust extents in pixel units and update display
                case 'push'
                    O.pushExtent(idx)
            end
            setBorders(O)
            % output?
            if nargout==0, clear idx, end
        end
    end
    
    % Positionning
    methods
        function updatePositions(O,idx)
            if nargin<2, idx = 1:O.nchildren; end
            % size of individual elements in pixel units
            xx = O.extents;
            % update panel positions
            [W H] = fn_pixelsize(O.hobj);
            for i = idx
                ci = O.children(i);
                xxi = xx(i);
                if ~fn_matlabversion('newgraphics'), xxi = max(1,xxi); end
                switch O.splitmode
                    case 'H'
                        set(ci.hobj,'units','pixel','pos',[sum(xx(1:i-1))+1 1 xxi H])
                    case 'V'
                        set(ci.hobj,'units','pixel','pos',[1 sum(xx(i+1:end))+1 W xxi])
                end
                set(ci.hobj,'visible',fn_switch(xx(i)>0))
            end
        end
        function extents = get.extents(O)
            extents = [O.children.extent];
        end
        function set.extents(O,extents)
            % convert extents to pixel units and update display

            % checks
            if length(extents)~=O.nchildren
                error 'length of extents input does not match number of children'
            end
            if all(extents==0), extents(:)=1; end % this can happen when containing panel has been squeezed to zero for some time in the past
            if O.nchildren==0, return, end
            
            % size of container in pixel units
            [W H] = fn_pixelsize(O.hobj);
            switch O.splitmode
                case 'H'
                    X = W;
                case 'V'
                    X = H;
            end
            
            % convert extents to pixels
            dorelative = [O.children.dorelative];
            xx = zeros(1,O.nchildren);
            xx(~dorelative) = extents(~dorelative);
            xx(dorelative) = extents(dorelative)/sum(extents(dorelative)) * (X-sum(xx));
            xx = round(max(0,xx));

            % update display
            [O.children.extent] = dealc(xx);
            updatePositions(O)
        end
        function pushExtent(O,idx,extent,figflag)
            % function pushExtent(O,idx,extent,'figleft|figright|...')
            %---
            % change figure size rather than adjust extent of 'relative
            % extent' panels
            % here, extent must be in pixel value, even if panel is of
            % 'relative extent'
            % a horrible flickering occurs when one attempts to keep a
            % panel at the same screen position, while changing the figure
            % size
            
            if nargin>=3, O.children(idx).extent = extent; end
            if nargin<4, figflag = ''; end
            if ~strcmp(get(O.hobj,'type'),'figure'), error 'object container is not a figure', end
            X = sum(O.extents);
            fpos0 = get(O.hobj,'pos'); fpos = fpos0;
            switch [O.splitmode figflag]
                case 'Hfigleft'
                    dx = X - fpos0(3);
                    fpos([1 3]) = [fpos0(1)-dx X];
                case {'Hfigright' 'H'}
                    fpos(3) = X;
                case 'Vfigtop'
                    fpos(4) = X;
                case {'Vfigbottom' 'V'}
                    dx = X - fpos0(4);
                    fpos([2 4]) = [fpos0(2)-dx X];
            end
            enableListener(O.szlistener,false)
            set(O.hobj,'pos',fpos)
            enableListener(O.szlistener,true)
            
            % update object
            switch O.splitmode
                case 'H'
                    updatePositions(O,idx:O.nchildren)
                case 'V'
                    updatePositions(O,1:idx)
            end
        end
    end
    
    % Borders
    methods (Access='private')
        function setBorders(O)
            borders0 = O.borders;
            for i=1:O.nchildren
                bi = borders0;
                switch O.splitmode
                    case 'H'
                        % top and down borders of each child control the
                        % borders of the main container
                        % except for the extremities, left and right borders
                        % control separations between sub-panels
                        if i>1, bi.left = {O i-1}; end
                        if i<O.nchildren, bi.right = {O i}; end
                    case 'V'
                        % the reciprocal
                        if i>1, bi.top = {O i-1}; end
                        if i<O.nchildren, bi.bottom = {O i}; end
                end
                O.children(i).borders = bi;
                ci = O.children(i);
                set(ci.hobj,'buttondownfcn',@(u,e)checkPanelSide(u,ci.borders))
                if ci.isorg
                    ci.org.borders = ci.borders;
                    setBorders(ci.org)
                end
            end
        end
        function moveBorder(O,idx)
            % special: if idx is a string, one can move a figure edge
            hf = fn_parentfigure(O.hobj);
            n = O.nchildren;
            if ischar(idx)
                if ~fn_switch(get(hf,'Resize')), return, end % not allowed to resize figure
                flag = idx;
                switch [O.splitmode flag]
                    case {'Hfigleft' 'Vfigtop'}
                        idx = 0;
                    case {'Hfigright' 'Vfigbottom'}
                        idx = n;
                    otherwise
                        % the side that is to be moved is not along the
                        % organization axis, so there is not much
                        % interesting to do
                        return
                end
                dopush = false;
            else
                dopush = strcmp(O.bordermode,'push');
            end
            
            % make current extent value all pixel unit
            xx0 = O.extents;
            
            % push all panels forward (and resize figure) or move border
            % between two panels without affecting the others?
            [dopushH dopushV] = deal(dopush&(O.splitmode=='H'), dopush&(O.splitmode=='V'));
            
            % move border
            p0 = get(0,'PointerLocation');
            fn_buttonmotion(@movesub,hf)
            function movesub
                
                % define motion
                drawnow, p = get(0,'PointerLocation');
                switch O.splitmode
                    case 'H'
                        dx = p(1)-p0(1);
                    case 'V'
                        dx = -(p(2)-p0(2));
                end
                if idx>0 && ~dopushV &&  xx0(idx)+dx<O.minext
                    % hide first panel
                    dx = -xx0(idx);
                elseif idx<n && ~dopushH && xx0(idx+1)-dx<O.minext
                    % hide second panel
                    dx = xx0(idx+1);
                end
                
                % update display
                xx = xx0; 
                if idx==0 || idx==n
                    % move figure edge
                    if idx==0
                        O.pushExtent(1,xx(1)-dx,flag)
                    else
                        O.pushExtent(n,xx(n)+dx,flag)
                    end
                else
                    % move border between two panels
                    if ~dopushV, xx(idx) = xx(idx)+dx; end
                    if ~dopushH, xx(idx+1) = xx(idx+1)-dx; end
                    if dopushH
                        O.pushExtent(idx,xx(idx),'figright')
                    elseif dopushV
                        O.pushExtent(idx+1,xx(idx+1),'figtop')
                    else
                        [O.children.extent] = dealc(xx);
                        O.updatePositions([idx idx+1])
                    end
                end
                
            end
            % update display of all children: this should be unnecessary,
            % but can fix some fast updates that were not accurate while
            % the border was being moved
            O.updatePositions()
        end
    end
    
    % Test
    methods (Static)
        function s = test
            s.hf = fn_figure('PANELORGANIZER TEST','handlevisibility','off');
            clf(s.hf)
            s.a = panelorganizer(s.hf,'H',2,[0 1],[300 1]);
            s.p2 = s.a.setSubPanel(2);
            s.a1 = s.a.setSubOrg(1,'V',3);
            s.p11 = s.a1.setSubPanel(1,'backgroundcolor','y');
            s.p13 = s.a1.setSubPanel(3);
            s.a12 = s.a1.setSubOrg(2,'H');
            s.uadd = uicontrol('parent',s.p11,'pos',[5 5 15 15],'string','+', ...
                'callback',@(u,e)s.a12.addSubPanel('backgroundcolor',rand(1,3)));
            s.uadd = uicontrol('parent',s.p11,'pos',[25 5 15 15],'string','-', ...
                'callback',@(u,e)s.a12.removeSubPanel(1));
        end
    end
    
end


%---
function checkPanelSide(u,borders)

% does current point fall close to a panel edge?
hf = fn_parentfigure(u);
p0 = get(hf,'currentpoint');
panelpos = fn_pixelpos(u,'recursive');
pixtol = 4;
if p0(1)<=panelpos(1)+pixtol
    % left border
    side = 'left';
elseif p0(1)>=sum(panelpos([1 3]))-pixtol
    % right border
    side = 'right';
elseif p0(2)<=panelpos(2)+pixtol
    % bottom border
    side = 'bottom';
elseif p0(2)>=sum(panelpos([2 4]))-pixtol
    % top border
    side = 'top';
else
    return
end

% which border to move (panelorganizer object and border index)
if isempty(borders.(side)), disp([side ' -> no move']), return, end
[O idx] = deal(borders.(side){:});

% change pointer
curpointer = get(hf,'pointer');
set(hf,'pointer',side)
c = onCleanup(@()set(hf,'pointer',curpointer));

% move
moveBorder(O,idx)

end

