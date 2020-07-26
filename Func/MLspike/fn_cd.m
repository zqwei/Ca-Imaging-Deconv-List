function repout = fn_cd(flag,varargin)
% function rep = fn_cd(flag,relpath)
% function fn_cd('edit')
% function [list = ] fn_cd('list')
%---
% This function allows user to rapidly change the current directory or get
% the full path to some files. 
%
% - Type 'fn_cd edit' to launch a GUI interface that enables you to define
%   your own absolute and relative paths (for example the full path to your
%   home, to which will be associated the flag 'home')
% - Then type 'fn_cd home' to set Matlab current directory to your home.
% - Type 'a = fn_cd('home');' to get the full path to your home (note that
%   this will not change Matlab current directory
% - Additional arguments to fn_cd can be used to access subdirectories or
%   files inside a flagged folder. For example, type 'fn_cd home dir1 dir2'
%   to set Matlab current directory to the subdirectory dir1/dir2 inside
%   your home directory, or type 'a = fn_cd('home','dir1/myfile');' to get
%   the full path to the file 'myfile' inside the subdirectory 'dir1'
%   inside your home directory.

% Thomas Deneux
% Copyright 2002-2017

if nargin==0, help fn_cd, return, end

% User define of new flags
switch flag
    case 'edit'
        fncdgui
        return
    case 'list'
        s = loaddef;
        if nargout==1
            repout = s;
        else
            list = char({s.label});
            list(:,end+1) = ' '; % add separator spaces
            [nitem nc] = size(list);
            W = matlab.desktop.commandwindow.size; W = W(1);
            ncol = max(1,floor((W+1)/nc));
            nrow = ceil(nitem/ncol);
            list(end+1:nrow*ncol,:) = ' ';
            list = fn_reshapepermute(list,[nrow ncol nc],{1 [3 2]});
            list(:,end) = []; % remove right-most separator spaces
            disp(list)
        end
        return
end
    
s = loaddef;
rep = getdir(s,flag);

if nargin>1
    rep = fullfile(rep,varargin{:});
end

if nargout==0
    try
        if ~isempty(rep), cd(rep), end
    catch %#ok<CTCH>
        disp(['definition ''' flag ''' -> ''' rep ''' is not valid!'])
    end
else 
    repout = rep;
end

end

%---
function path = resolvehost(path)
if isstruct(path)
    khost = strcmp(fn_hostname(),{path.host});
    if ~sum(khost), path = ''; return, end % error!
    path = path(khost).path;
end
end

%---
function fname = getdir(s,i)
if ischar(i)
    label = i;
    i = find(strcmp(label,{s.label}));
    if ~isscalar(i), fname = ''; return, end % error!
end
fname = resolvehost(s(i).path);
if ~isempty(s(i).relto)
    base = getdir(s,s(i).relto);
    if isempty(base)
        fname = '';
    else
        fname = fullfile(base,fname);
    end
elseif isempty(fileparts(fname))
    % string has no separator; it might be a Matlab command, such as
    % 'prefdir'
    try fname = eval(fname); end %#ok<TRYNC>
end
end

%---
function s = loaddef
s = fn_userconfig('fn_cd');
if isempty(s)
    s = struct('label',{'example1' 'example2'},'relto',{'' 'example1'},'path',{'/home/deneux' 'Matlab'});
end
end

%---
function savedef(s) 
fn_userconfig('fn_cd',s)
end

%---
function fncdgui

% position parameters
H = 600;
W = 560;
d = 5;

w1 = 80;
w2 = w1;
w3 = 18;
w3label = 120;
w5 = 35;
w4 = W - (d+w1+d+w2+d+w3+d+d+w5+d);
wp = 150;
ws = 60;
hh = 18;
ht = 23;
hd = ht-hh;
nlin = floor((H-hd)/ht);
ndefperpage = nlin-1;

% figure
hf = figure(726);
fn_setfigsize(hf,W,H);
set(hf,'numbertitle','off','name',['FN_CD (current host: ' fn_hostname() ')'])
set(hf,'defaultuicontrolhorizontalalignment','left')

% load definitions if exist
s = loaddef();
ndef = length(s);
npage = ceil(ndef/ndefperpage);

% sort definitions
[~, ord] = sortrows([fn_map(s,@(u)char('A'+~isstruct(u.path)),'cell')' {s.relto}' {s.label}']);
s = s(ord);

% first line
uicontrol('style','text','string','label','pos',[d H-ht w1 hh])
uicontrol('style','text','string','relative to','pos',[d+w1+d H-ht w2 hh])
uicontrol('style','text','string','host dependent?','pos',[d+w1+d+w2+d H-ht w3label hh])
pagestr = [cellstr(num2str((1:npage)','page %i')); 'new page'];
kpage = npage;
hupage = uicontrol('style','popupmenu', ...
    'string',pagestr,'value',kpage, ...
    'pos',[W-d-ws-d-wp H-ht wp hh], ...
    'callback',@(u,e)chgpage(get(u,'value')));
uicontrol('style','pushbutton','string','SAVE', ...
    'pos',[W-d-ws H-ht ws hh], ...
    'callback',@(u,e)saveit())

% definition lines
hu = zeros(3,ndefperpage);
hm = zeros(1,ndefperpage);
for k=1:ndefperpage
    % we first display all the 'edit' controls, so that they come next to
    % each other when pressing the Tab key
    hu(1,k) = uicontrol('style','edit', ...
        'pos',[d H-(k+1)*ht w1 hh], ...
        'callback',@(u,e)chgdef(k));
    hu(2,k) = uicontrol('style','edit', ...
        'pos',[d+w1+d H-(k+1)*ht w2 hh], ...
        'callback',@(u,e)chgdef(k));
    hu(3,k) = uicontrol('style','edit', ...
        'pos',[d+w1+d+w2+d+w3+d H-(k+1)*ht w4 hh], ...
        'callback',@(u,e)chgdef(k));
end
for k=1:ndefperpage
    % we next display the checkboxes (for hostname depedency) and the
    % buttons for user access to directories
    hm(k) = uicontrol('style','checkbox', ...
        'pos',[d+w1+d+w2+d H-(k+1)*ht w3 hh], ...
        'callback',@(u,e)chgdef(k));
    uicontrol('style','pushbutton','string','D', ...
        'pos',[d+w1+d+w2+d+w3+d+w4+d H-(k+1)*ht w5 hh], ...
        'callback',@(u,e)userdir(k));
end
displaypage()

    function displaypage()
        for k=1:ndefperpage
            kdef = (kpage-1)*ndefperpage + k;
            if kdef>ndef || isempty(s(kdef).label)
                % no definition exists
                set(hu(:,k),'string','','backgroundcolor','default')
                set(hm(k),'value',0)
            else
                % definition exists
                sk = s(kdef);
                fn_set(hu(:,k),'string',{sk.label,sk.relto,resolvehost(sk.path)})
                set(hm(k),'value',isstruct(sk.path))
                checkdir(k)
            end
        end
    end
    function chgpage(k)
        kpage = k;
        if kpage>npage
            npage = kpage;
            pagestr = [cellstr(num2str((1:npage)','page %i')); 'new page'];
            set(hupage,'string',pagestr);
        end
        displaypage();
    end
    function chgdef(k)
        kdef = (kpage-1)*ndefperpage + k;
        c = fn_get(hu(:,k),'string');
        if isempty(c{1})
            % no label -> remove entry
            if kdef<=ndef
                s(kdef) = [];
                ndef = length(s);
                displaypage()
            end
            return
        end
        [s(kdef).label s(kdef).relto path] = deal(c{:});
        if get(hm(k),'value')
            % host name - specific definition
            sk = s(kdef);
            path = struct('host',fn_hostname(),'path',path);
            if isstruct(sk.path)
                khost = find(strcmp(path.host,{sk.path.host}));
                if isempty(khost)
                    khost = length(sk.path)+1;
                elseif ~isscalar(khost)
                    error programming
                end
                s(kdef).path(khost) = path;
            else
                s(kdef).path = path;
            end
        else
            % not host name - specific
            s(kdef).path = path;
        end
        for i=1:ndefperpage, checkdir(i), end
        if kdef>ndef, ndef=kdef; end
    end
    function checkdir(k)
        kdef = (kpage-1)*ndefperpage + k;
        if kdef>ndef, set(hu(:,k),'backgroundcolor','w'), return, end
        fname = getdir(s,kdef);
        if isempty(s(kdef).label)
            error 'empty labels should be detected upstream'
            %set(hu(:,k),'backgroundcolor','default','string','')
        elseif exist(fname,'dir')
            set(hu(:,k),'backgroundcolor','w')
        else
            set(hu(:,k),'backgroundcolor',[1 .5 0])
        end
    end
    function userdir(k)
        kdef = (kpage-1)*ndefperpage + k;
        path = fn_getdir;
        if isequal(path,0), return, end
        if kdef<=ndef && ~isempty(s(kdef).relto)
            s(kdef).path = '';
            relto = getdir(s,kdef);
            if isempty(relto), return, end
            if length(path)<length(relto) || ~all(relto==path(1:length(relto)))
                errordlg(['selected directory is not inside '' s(kdef).relto '''])
                return
            end
            path = path(length(relto)+1:end);
        end
        set(hu(3,k),'string',path)
        chgdef(k)
    end
    function saveit()
        savedef(s)
        assignin('base','s',s)
    end

end










