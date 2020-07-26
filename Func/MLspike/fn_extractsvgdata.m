classdef fn_extractsvgdata < handle
    % function fn_extractsvgdata(fname)
    %---
    % Display SVG data and provide tools to extract curve data.
    
    % Thomas Deneux
    % Copyright 2015-2017

    % SVG format (as far as i could get)
    % .svg                      full document
    %  .metadata                (ignored)
    %  .defs                    (ignored)
    %  .sodipodi:namedview      (ignored)
    %  .g                       main container for all graphic elements
    %   .g                      multiple structure, all graphic elements
    %    attributes: id, transform
    %    .path
    %     attributes: id, d, style
    %   .txt                    multiple structure, all text elements (ignored for now)
    %    attributes: id, transform
    %    .tspan
    %     attributes: id, sodipodi:role, style, x, y
    %     content: the text itself
    
    properties
        ha
        elements = struct('poly',cell(1,0),'style',[],'hl',[]);
        mc
        curidx
        curaxis
        options
    end
    
    % Read and display
    methods
        function E = fn_extractsvgdata(fname)
            
            % Input
            if nargin==0
                fname = fn_getfile('*.svg','Select .svg file to read');
                %fname = evalin('base','x');
            end
            if ischar(fname)
                xml = fn_readxml(fname);
            elseif isstruct(fname)
                % input is already the structure output of xml reading
                xml = fname;
            else
                error 'could not interpret input'
            end
            
            % List of graphic elements (ignoring text for now), ID, transform
            g = xml.g.g;
            
            % Prepare figure and context menus
            clf
            m = uicontextmenu;
            uimenu(m,'label','zoom out','callback',@(u,e)zoomout(E))
            E.ha = gca;
            set(E.ha,'uicontextMenu',m)
            E.mc = uicontextmenu;
            uimenu(E.mc,'label','extract data','callback',@(u,e)extractdata(E))
            uimenu(E.mc,'label','set xmin','callback',@(u,e)setaxis(E,'xmin'),'separator','on')
            uimenu(E.mc,'label','set xmax','callback',@(u,e)setaxis(E,'xmax'))
            uimenu(E.mc,'label','set ymin','callback',@(u,e)setaxis(E,'ymin'))
            uimenu(E.mc,'label','set ymax','callback',@(u,e)setaxis(E,'ymax'))
            uimenu(E.mc,'label','xmin+xmax','callback',@(u,e)setaxis(E,{'xmin' 'xmax'}),'separator','on')
            uimenu(E.mc,'label','ymin+ymax','callback',@(u,e)setaxis(E,{'ymin' 'ymax'}))
            uimenu(E.mc,'label','xmin+ymin','callback',@(u,e)setaxis(E,{'xmin' 'ymin'}))
            uimenu(E.mc,'label','xmin+xmax+ymin','callback',@(u,e)setaxis(E,{'xmin' 'xmax' 'ymin'}))
            uimenu(E.mc,'label','xmin+ymin+ymax','callback',@(u,e)setaxis(E,{'xmin' 'ymin' 'ymax'}))
            uimenu(E.mc,'label','all','callback',@(u,e)setaxis(E,{'xmin' 'xmax' 'ymin' 'ymax'}))
            axis image
            
            % Read element by element
            nfail = 0;
            warnings = false;
            for i=1:length(g)
                %try 
                    warnings = warnings | readoneelem(E,g(i));
                %catch
                %    nfail = nfail+1;
                %end
            end
            if nfail, fprintf('Failed to display %i elements out of %i\n',nfail,length(g)), end
            
            % Display encountered warnings
            [warncurve] = dealc(warnings);
            if warncurve
                disp('Bézier commands and elliptical arcs will not be displayed properly')
            end
            
            % Add zoom-in ability
            set(E.ha,'buttondownfcn',@(u,e)zoomin(E))
            zoomout(E)
            
            % Options
            init_options(E)
            
            % Object in base workspace
            assignin('base','E',E)
        end
        
        function warnings = readoneelem(E,g)
            
            %             % id
            %             id = x.ATTRIBUTE.id;
            
            % group?
            if isfield(g,'g') && ~isempty(g.g)
                if isfield(g.ATTRIBUTE,'transform')
                    warning 'group transformation not handled yet'
                end
                warnings = false;
                for i=1:length(g.g)
                    warnings = warnings | readoneelem(E,g.g(i));
                end
                return
            end
            
            % transformation
            if isfield(g.ATTRIBUTE,'transform')
                transform = g.ATTRIBUTE.transform;
                tokens = regexp(transform,'^(.*)\((.*)\)$','tokens');
                if isempty(tokens)
                    error 'could not read ''transform'' string'
                end
                tokens = tokens{1};
                type = tokens{1};
                switch type
                    case 'translate'
                        translation = column(str2num(tokens{2}));
                        rotation = 1;
                    case 'scale'
                        translation = [0;0];
                        rotation = column(str2num(tokens{2}));
                    case 'matrix'
                        spec = str2num(tokens{2}); %#ok<ST2NM>
                        if length(spec)~=6, error 'could not read matrix data', end
                        translation = column(spec(5:6));
                        rotation = reshape(spec(1:4),2,2);
                    otherwise
                        error('unknown transform type ''%s''',type)
                end
            else
                translation = 0;
                rotation = 1;
            end
            
            warncurve = false;
            
            % path (https://www.w3.org/TR/SVG/paths.html#DAttribute)
            if ~isfield(g,'path'), warnings = false; return, end
            for i=1:length(g.path)
                d = g.path(i).ATTRIBUTE.d;
                parts = regexp(d,'[a-zA-Z][\d-. ,]+','match');
                polys = {};
                poly = [];
                for k=1:length(parts)
                    partk = parts{k};
                    command = partk(1);
                    points = reshape(str2num(partk(2:end)),2,[]);
                    if k==1 && ~ismember(command,'mM'), error 'path must begin with a ''moveto'' instruction', end
                    switch command
                        case {'m' 'M'}
                            % moveto
                            if k>1
                                p0 = poly(:,end);
                                polys{end+1} = fn_add(translation,rotation*poly); %#ok<AGROW>
                                poly = [];
                            else
                                p0 = 0;
                            end
                            if strcmp(command,'m')
                                % relative moveto
                                points = fn_add(p0,cumsum(points,2));
                            end
                        case 'L'
                            % absolute lineto: nothing to do
                        case 'l'
                            % relative lineto
                            points = fn_add(poly(:,end),cumsum(points,2));
                        case {'C' 'S' 'Q' 'T' 'A'}
                            % absolute Bézier/arc
                            warncurve = true;
                            points = points(:,end); % the target point
                        case {'c' 's' 'q' 't' 'a'}
                            % relative Bézier/arc
                            warncurve = true;
                            points = poly(:,end)+points(:,end); % the target point
                    end
                    poly = [poly points]; %#ok<AGROW>
                end
                polys{end+1} = fn_add(translation,rotation*poly); %#ok<AGROW>
                
                % style
                style = g.path(i).ATTRIBUTE.style;
                tokens = regexp(style,'([^:;]*):([^:;]*)','tokens');
                ok = false(1,length(tokens));
                for i=1:length(tokens)
                    [name value] = deal(tokens{i}{:});
                    switch name
                        case 'stroke'
                            ok(i) = true;
                            if strcmp(value,'none')
                                tokens{i} = {'linestyle','none'};
                            else
                                tokens{i} = {'color',getcolor(value)};
                            end
                    end
                end
                style = [tokens{ok}];
                
                % ignore path with no stroke
                idx = find(strcmp(style(1:2:end),'linestyle'),1);
                if ~isempty(idx) && strcmp(style{2*idx},'none')
                    continue
                end
                
                % display
                for kpoly = 1:length(polys)
                    poly = polys{kpoly};
                    
                    % try connecting lines that look like in continuation of each other
                    doconnect = false;
                    if ~isempty(E.elements)
                        lastelem = E.elements(end);
                        if ~isempty(lastelem.poly) && isequal(style,lastelem.style) 
                            if norm(poly(:,1)-lastelem.poly(:,end))<.1
                                % connect to the end of previous
                                poly = [lastelem.poly poly(:,2:end)];
                                doconnect = true;
                            elseif norm(poly(:,end)-lastelem.poly(:,1))<.1
                                % connect to the begin of previous
                                poly = [poly lastelem.poly(:,2:end)];
                                doconnect = true;
                            end
                        end
                    end
                    
                    % display
                    if doconnect
                        set(lastelem.hl,'xdata',poly(1,:),'ydata',poly(2,:))
                        E.elements(end).poly = poly;
                    else
                        idx = length(E.elements)+1;
                        hl = line(poly(1,:),poly(2,:),style{:},'buttondownfcn',@(u,e)linepress(E,idx));
                        E.elements(idx) = struct('poly',poly,'style',{style},'hl',hl);
                    end
                end
            end
            
            % output warning(s)
            warnings = warncurve;
            
        end
        
        function init_options(E)
            % options control
            s = struct( ...
                'doprompt',     {true   'logical'   'prompt for name'}, ...
                'xname',        {'x'    'char'      'auto x-name'}, ...
                'yname',        {'y'    'char'      'auto y-name'}, ...
                'index',        {1      'stepper 1 1 Inf 1'     'index'});
            E.options = fn_control(s);
            % figure not visible initially, cannot be closed (becomes
            % invisible instead), gets opened by menu
            hp = E.options.hp;
            set(hp,'visible','off','closerequestfcn',@(u,e)set(u,'visible','off'))
            uimenu(gcf,'label','Show Options','callback',@(u,e)set(hp,'visible','on'))
            set(gcf,'DeleteFcn',@(u,e)delete(hp))
        end
    end
    
    % Extract data
    methods
        function linepress(E,i)
            if strcmp(get(gcf,'SelectionType'),'open')
                extractdata(E)
                return
            end
            if ~isempty(E.curidx)
                set(E.elements(E.curidx).hl,'SelectionHighlight','off','Selected','off')
                if E.curidx==i, E.curidx=[]; return, end
            end
            E.curidx = i;
            set(E.elements(i).hl,'SelectionHighlight','on','Selected','on')
            p = get(gca,'currentpoint'); p = p(1,1:2);
            set(E.mc,'visible','on','pos',[p(1)+50 p(2)])
        end
        function setaxis(E,flags)
            % current path
            if isempty(E.curidx), return, end
            poly = E.elements(E.curidx).poly;
            % prompt user for value
            if ~iscell(flags), flags = {flags}; end
            dataval = struct; 
            for k=1:length(flags)
                flag = flags{k};
                if strfind(flag,'min'), dataval.(flag) = 0; else dataval.(flag) = 1; end
            end
            dataval = fn_structedit(dataval);
            if isempty(dataval), return, end
            % current axis
            if isempty(E.curaxis)
                axis tight
                ax = axis;
                E.curaxis = struct('axis',ax,'values',ax);
            end
            % loop on flags
            for k=1:length(flags)
                flag = flags{k};
                % drawing coordinates
                switch flag
                    case 'xmin'
                        idx = 1;
                        val = min(poly(1,:));
                    case 'xmax'
                        idx = 2;
                        val = max(poly(1,:));
                    case 'ymin'
                        idx = 3;
                        val = min(poly(2,:));
                    case 'ymax'
                        idx = 4;
                        val = max(poly(2,:));
                end
                E.curaxis.axis(idx) = val;
                % data coordinates
                E.curaxis.values(idx) = dataval.(flag);
            end
            % update display
            xtick = E.curaxis.axis(1:2); xlim = mean(xtick) + [-.6 .6]*diff(xtick);
            ytick = E.curaxis.axis(3:4); ylim = mean(ytick) + [-.6 .6]*diff(ytick);
            vals = E.curaxis.values;
            set(gca,'xlim',xlim,'ylim',ylim, ...
                'xtick',xtick,'xticklabel',{num2str(vals(1)) num2str(vals(2))}, ...
                'ytick',ytick,'yticklabel',{num2str(vals(3)) num2str(vals(4))})
            % unselect curve
            set(E.elements(E.curidx).hl,'SelectionHighlight','off','Selected','off')
            E.curidx = [];
        end
        function extractdata(E)
            % current path
            if isempty(E.curidx), return, end
            poly = E.elements(E.curidx).poly;
            % convert to data coordinates
            if isempty(E.curaxis), errordlg 'Define coordinate conversion first', return, end
            ax = E.curaxis;
            xdata = ax.values(1) + (poly(1,:)-ax.axis(1))/diff(ax.axis(1:2))*diff(ax.values(1:2));
            ydata = ax.values(3) + (poly(2,:)-ax.axis(3))/diff(ax.axis(3:4))*diff(ax.values(3:4));
            % assign in base workspace
            X = E.options;
            varnames = {sprintf('%s%i',X.xname,X.index) sprintf('%s%i',X.yname,X.index)};
            if X.doprompt
                varnames = inputdlg({'Variable name for x-data' 'Variable name for y-data'}, ...
                    'Extract data',1,varnames);
            end
            assignin('base',varnames{1},xdata(:))
            assignin('base',varnames{2},ydata(:))
            if ~X.doprompt
                fprintf('data saved in variables %s and %s\n',varnames{1},varnames{2})
            end
            X.index = X.index+1;
            % unselect curve
            set(E.elements(E.curidx).hl,'SelectionHighlight','off','Selected','off')
            E.curidx = [];
        end
        function zoomin(E)
            ax = fn_mouse(E.ha,'rectax-');
            if ~diff(ax(1:2)) || ~diff(ax(3:4)), return, end
            axis(E.ha,ax)
        end
        function zoomout(E)
            E.curaxis = [];
            fn_axis(gca,'tight',1.2)
            set(gca,'xtickmode','auto','xticklabelmode','auto','ytickmode','auto','yticklabelmode','auto')
        end
    end
end

%---
function col = getcolor(str)

col = double([hex2dec(str(2:3)) hex2dec(str(4:5)) hex2dec(str(6:7))])/255;

end
