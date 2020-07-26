function out = fn_savefig(varargin)
% function fn_savig([hobj][,fname][,options...])
% function im = fn_savig([hobj][,options...])
%---
% Save an image of one or several figure(s). Large number of options
% are available. 
% If function is called with no argument, or only with hf, an interface is
% displayed that lets user choose the saving options.
% If an output is requested, this forces 'capture' method and no file is
% saved.
% 
% Input:
% - hobj        vector of figure handles [default: current figure], or axes
%               handle ('capture' method only)
% - fname       char array or cell array - file name(s) [default: prompt
%               user]
%               if 'show', show captured image in new figure instead (of
%               saving); if 'clipboard', copies to clipboard instead
% - 'askname' or 'autoname'     prompt or do not prompt user for figure
%               name, but build an automatic name, inside folder
%               fn_cd('capture') [default]
% - format      'png', 'bmp', 'jpg', 'svg', 'eps', 'ps' or 'fig', or a cell
%               array with several formats [default: inferred from file
%               name, or 'png' if file name has no extension]
% - 'capture' or 'savefig'  capture method: 'capture' [default unless a
%               vector format is requested] uses Matlab function 
%               getframe to capture an image which is saved to a file
%               (i.e. the image will be strictly identical to what is seen
%               on screen); 'savefig' uses Matlab function saveas to save
%               (i.e. display will be changed according to some figure
%               properties such as 'PaperPosition', see also parameter
%               'scaling' below)
% - 'subframe'  user select a sub-part of the figure to save ('capture'
%               method only)
% - rectangle   a 4-element vector defining the sub-part of the figure to
%               save ('capture' method only)
% - 'content'   cut image to remove white sides ('capture' method only)
% - scaling     a scalar that defines by how much to scale the figure
%               compared to screen display ('savefig' method only)
% - 'append', 'append+pdf' or 'ps2pdf'  append to file (ps file only) and
%               make pdf if specified ('ps2pdf' does not save the figure,
%               but only convert existing ps file to pdf)
% 
% See also: fn_saveimg

% Thomas Deneux
% Copyright 2003-2017


% Input
% (prompt user or scan input)
if nargin==0 || (nargin==1 && all(fn_isfigurehandle(varargin{1})))
    hfig = fn_switch(nargin,0,[],1,varargin{1});
    doax = false;
    s = struct( ...
        'autoname',     {true       'logical'   'auto figure name'}, ...
        'method',       {''         {'' 'capture' 'save figure'} 'method'}, ...
        'subframe',     {'full image' {'full image' 'select sub-rectangle' 'remove white sides'} 'cut image (''capture'' only)'}, ...
        'output',       {'save to file' {'save to file' 'copy to clipboard' 'show in new figure'} 'output'}, ... % option 'output' also exists
        'scaling',      {[]         'xdouble'    'scaling (''save figure'' only)'}, ...
        ... 'invertcolor',  {false      'logical'   'white background (''save figure'' only)'}, ...
        'format',       {'png'      {'png' 'jpg' 'svg' 'eps' 'ps' 'pdf' 'fig'} 'file format'}, ...
        'append',       {'no'       {'no' 'append' 'append+pdf'} 'append (ps file only)'} ...
        );
    s = fn_structedit(s);
    if isempty(s), return, end
    s.invertcolor = [];
    if isempty(s), return, end % canceled
    fname = {};
    s.format = {s.format};
    if strcmp(s.method,'save figure'), s.method = 'savefig'; end
    rect = {};
    switch s.output
        case 'copy to clipboard'
            fname = {'clipboard'};
        case 'show in new figure'
            fname = {'show'};
    end
    s = rmfield(s,'output');
else
    hfig = []; doax = false;
    fname = {};
    rect = {};
    s = struct('autoname',false,'method','','subframe','full image', ...
        'scaling',[],'format',{{}},'invertcolor',[],'append','no');
    k = 0;
    while k<length(varargin)
        k = k+1;
        a = varargin{k};
        if isnumeric(a) && isvector(a) && length(a)==4 && any(a(1:2)>20)
            rect = {a};
        elseif isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')
            doax = true;
            ha = a;
            if ~isempty(hfig), error 'cannot specify an axes handle if some figure handle(s) was already specified', end
            hfig = fn_parentfigure(ha);
        elseif isempty(hfig) && ~doax && all(fn_isfigurehandle(a))
            hfig = a;
        elseif isnumeric(a) && isempty(s.scaling)
            s.scaling = a;
        elseif isnumeric(a)
            % problem: what we thought was a scaling parameter was
            % actually a figure handle!?
            if ~fn_isfigurehandle(s.scaling), error 'numeric argument seems to be neither a figure handle, neither a scaling parameter', end
            hfig = [hfig s.scaling]; %#ok<AGROW>
            s.scaling = a;
        elseif iscell(a)
            if fn_ismemberstr(a{1},{'png' 'bmp' 'jpg' 'svg' 'eps' 'ps' 'pdf' 'fig'})
                s.format = lower(a);
            else
                fname = a;
            end
        elseif ischar(a)
            if ~isvector(a)
                fname = cellstr(a);
            elseif fn_ismemberstr(a,{'scale' 'scaling'})
                k = k+1;
                s.scaling = varargin{k};
            elseif strcmp(a,'autoname')
                s.autoname = true;
            elseif strcmp(a,'askname')
                s.autoname = false;
            elseif fn_ismemberstr(a,{'capture' 'savefig'})
                s.method = a;
            elseif strcmp(a,'subframe')
                s.subframe = 'select sub-rectangle';
            elseif strcmp(a,'content')
                s.subframe = 'remove white sides';
            elseif fn_ismemberstr(a,{'showonly' 'show only'})
                disp 'warning: ''showonly'' or ''show only'' flags are obsolete, use ''show'' instead'
                fname{end+1} = 'show'; %#ok<AGROW>
            elseif fn_ismemberstr(a,{'png' 'bmp' 'jpg' 'svg' 'eps' 'ps' 'pdf' 'fig'})
                s.format{end+1} = lower(a);
            elseif fn_ismemberstr(a,{'append','append+pdf','ps2pdf'})
                s.append = a;
            elseif any(a==',')
                % formats separated by commas
                tmp = fn_strcut(a,', ');
                if ~all(ismember(tmp,{'png' 'bmp' 'jpg' 'svg' 'eps' 'ps' 'pdf' 'fig'}))
                    disp(['interpreting ''' a ''' as a file name'])
                    fname{end+1} = a; %#ok<AGROW>
                else
                    s.format = [s.format tmp];
                end
            else
                fname{end+1} = a; %#ok<AGROW>
            end
        elseif isnumeric(a)
            s.scaling = a;
        else
            error argument
        end
    end
    if nargout>=1
        fname{end+1} = 'output';
    end
end
% (figure(s))
if isempty(hfig), hfig = gcf; end
nfig = length(hfig);
% (file names)
if ~isempty(fname)
    if ~isscalar(fname) && nfig==1
        nfig = length(fname);
        hfig = repmat(hfit,1,nfig);
    elseif length(fname)~=nfig
        error 'number of file names does not match number of figures';
    end
elseif s.autoname
    fname = cell(1,nfig);
    for k=1:nfig, fname{k} = [fn_autofigname(hfig(k)) '_scale' num2str(s.scaling)]; end
else
    fname = cell(1,nfig);
    for k=1:nfig
        fname{k} = fn_savefile( ...
            '*.png;*.PNG;*.bmp;*.BMP;*.jpg;*.JPG;*.svg;*.SVG;*.eps;*.EPS;*.ps;*.PS;*.pdf;*.PDF;*.fig;*.FIG', ...
            ['Select file where to save figure ' figname(hfig(k))]);
        if ~fname{k}, return, end
    end
end

% Save
for k=1:nfig
    hfk = hfig(k);
    fnamek = fname{k};
    
    % format
    format = cell(1,nfig);
    [p base ext] = fileparts(fnamek);
    fbasek = fullfile(p,base);
    dosavefile = ~ismember(fnamek,{'clipboard' 'show' 'output'});
    if ~dosavefile
        formatk = fnamek;
    elseif isempty(ext)
        if isempty(s.format), formatk = {'png'}; else formatk = s.format; end
    else
        ext = lower(ext(2:end)); % remove the dot and use lower case
        if ~isempty(s.format) && ~isequal(s.format,{ext})
            %disp 'incompatible format definitions'
            fbasek = [fbasek '.' ext]; %#ok<AGROW>
            formatk = s.format;
        else
            formatk = {ext};
        end
    end
    
    % determine method
    method = s.method;
    if ismember(formatk,{'svg' 'eps' 'ps' 'pdf' 'fig'}) || ~isempty(s.scaling)
        if strcmp(method,'capture'), error '''capture'' cannot save vector format files or adjust the scaling', end
        method = 'savefig';
    end
    if ismember(formatk,{'clipboard' 'show' 'output'}) || ~strcmp(s.subframe,'full image') || doax
        if strcmp(method,'savefig'), error '''savefig'' method cannot save a figure subpart', end
        if ~strcmp(s.subframe,'full image') && doax, error 'cannot select a subpart of an axes', end
        method = 'capture';
    end
    if isempty(method), method = 'capture'; end
    
    % save image using specified method
    switch method
        case 'savefig'
            % remove as many callbacks as possible, prepare uicontrols
            if doax, error 'when saving only an axes, only ''capture'' method is available', end
            state = preparefig(hfk,any(strcmp(formatk,'fig')));
            % add an axes to prevent ps2pdf bug on images
            if any(ismember(formatk,{'ps' 'pdf'}))
                ha = findall(hfig(k),'tag','axes_for_ps2pdf_bug');
                if isempty(ha)
                    ha = axes('parent',hfig(k),'pos',[-1 -1 .1 .1],'handlevisibility','off');
                end
                uistack(ha,'bottom')
            end
            % change paperposition property
            pos = fn_getpos(hfk,'inches'); % position in the screen
            if isempty(s.scaling), s.scaling = 1; end
            paperpos = [0 0 pos([3 4])*s.scaling];
            set(hfk,'paperUnits','inches','paperposition',paperpos)     % keep the same image ratio
            invertcolor = s.invertcolor;
            if isempty(invertcolor)
                invertcolor = isempty(findall(hfk,'type','uicontrol'));
            end
            set(hfk,'inverthardcopy',fn_switch(invertcolor))
            printflags = fn_switch(invertcolor,{},{'-loose'});
            for i=1:length(formatk)
                fnamei = [fbasek '.' formatk{i}];                              % [new: pdf direct] 
                formatki = fn_switch(formatk{i},{'eps' 'ps'},'psc2',formatk{i}); % [new: pdf direct]
                if strcmp(formatki,'fig')
                    saveas(hfk,fnamei)
                else
                    if strcmp(formatk{i},'ps') && any(strfind(s.append,'append')) && exist([fbasek '.ps'],'file')
                        printflags{end+1}='-append'; %#ok<AGROW>
                    end
                    if ~strcmp(s.append,'ps2pdf')
                        print(hfk,fnamei,['-d' formatki],printflags{:})
                    end
                    % if strcmp(formatk{i},'pdf') || (strcmp(formatk{i},'ps') && any(strfind(s.append,'pdf'))) % [old: pdf through ps] 
                    if strcmp(formatk{i},'ps') && any(strfind(s.append,'pdf')) % [new: pdf direct] 
                        ps2pdf('psfile',[fbasek '.ps'],'pdffile',[fbasek '.pdf'], ...
                            'gspapersize',fn_strcat(paperpos(3:4),'x'),'deletepsfile',1,'verbose',0)
                    end
                end
            end
            % restore callbacks and so on
            restorefig(state)
        case 'capture'
            if strcmp(s.subframe,'select sub-rectangle')
                rect = {fn_figselection(hfk)};
            elseif doax
                rect = {fn_pixelpos(ha,'recursive','strict')};
            end
            im = getfield(getframe(hfk,rect{:}),'cdata');
            if strcmp(s.subframe,'remove white sides')
                bg = im(1,1,:);
                isbg = all(fn_eq(im,bg),3);
                ii = find(~all(isbg,2),1,'first'):find(~all(isbg,2),1,'last');
                jj = find(~all(isbg,1),1,'first'):find(~all(isbg,1),1,'last');
                im = im(ii,jj,:);
            end
            if doax
                % remove sides
                im = im(2:end-1,2:end-1,:);
            end
            if dosavefile
                for i=1:length(formatk)
                    imwrite(im,[fbasek '.' formatk{i}],formatk{i})
                end
            else 
                switch formatk
                    case 'show'
                        [ny nx nc] = size(im); %#ok<ASGLU>
                        hfnew = figure; fn_setfigsize(hfnew,nx,ny);
                        axes('pos',[0 0 1 1])
                        image(im)
                        set(gca,'xtick',[],'ytick',[])
                    case 'clipboard'
                        imclipboard('copy',im)
                    case 'output'
                        out = permute(im,[2 1 3]);
                end
            end
    end
end

% reset paperposition property to allow use of saveas


%---
function state = preparefig(hf,docallbacks)

% objects
state.hf = hf;
state.controls = unique(findall(hf,'type','uicontrol'));

% store properties
state.controlsprop = fn_get(state.controls,'visible','struct');

% overwrite properties
% (hide controls who are not visible because a parent is not visible)
for i=1:length(state.controls)
    ui = state.controls(i);
    hobj = ui;
    while ~strcmp(get(hobj,'type'),'figure')
        if strcmp(get(hobj,'visible'),'off')
            set(ui,'visible','off')
            break
        end
        hobj = get(hobj,'parent');
    end    
end

if ~docallbacks, return, end

% store callback properties
allobj = findall(hf);
state.allobj = allobj(~strcmp(get(allobj,'type'),'uimenu'));
state.buttons = allobj(ismember(get(allobj,'type'),{'uicontrol' 'uimenu'}));
state.spec = allobj(ismember(get(allobj,'type'),{'uipanel'}));
winprop = {'windowbuttondownfcn' 'windowbuttonupfcn' 'windowbuttonmotionfcn' ...
    'keypressfcn' 'windowkeypressfcn' 'windowkeyreleasefcn' 'windowscrollwheelfcn' ...
    'closerequestfcn' 'handlevisibility'};
state.figcallbacks = fn_get(hf,winprop,'struct');
state.butcallbacks = fn_get(state.buttons,{'callback' 'keypressfcn'},'struct');
state.speccallbacks = fn_get(state.spec,{'SelectionChangeFcn'},'struct');
state.allcallbacks = fn_get(state.allobj,{'userdata' 'buttondownfcn' 'createfcn' 'deletefcn' 'resizefcn' 'appdata'},'struct');

% overwrite properties
fn_set(hf,winprop,'default') % note that the default for 'closerequestfcn' is @closereq
fn_set(state.buttons,{'callback' 'keypressfcn'},'')
fn_set(state.spec,{'SelectionChangeFcn'},'')
fn_set(state.allobj,{'userdata' 'buttondownfcn' 'createfcn' 'deletefcn' 'resizefcn' 'appdata'},{[] '' '' '' '' struct})

%---
function restorefig(state)

fn_set(state.controls,state.controlsprop)

if ~isfield(state,'allobj'), return, end

fn_set(state.hf,state.figcallbacks)
fn_set(state.buttons,state.butcallbacks);
fn_set(state.spec,state.speccallbacks)
fn_set(state.allobj,state.allcallbacks)

%---
function name = figname(hf)
% function name = figname(hf)
%---
% get a meaningful name for a given figure

name = get(hf,'name');
if isempty(name)
    num = get(hf,'number');
    if ~isempty(num), name = num2str(num); end
end
