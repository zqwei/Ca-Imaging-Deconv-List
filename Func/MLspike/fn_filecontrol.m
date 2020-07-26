function hu = fn_filecontrol(varargin)
% function hu = fn_filecontrol([hu,]'property1',value1,...)
%---
% Set the properties of a regular uicontrol with style 'edit' so that
% clicking in it lets user select a file.
%
% Input
% - hu                      uicontrol handle
% - 'property1',value1,...  pairs of property names and values; a few
%                           custom properties are available:
%                           - 'mode' can be set to 'get', 'save' [default] or 'dir'
%                           - 'filter' indicates a filter to user [default is '*']

% Thomas Deneux
% Copyright 2015-2017

% Input
if mod(nargin,1)
    hu = varargin{1};
    options = varargin(2:end);
else
    options = reshape(varargin,2,nargin/2);
    kparent = find(strcmp(options(1,:),'parent'));
    if ~isempty(kparent)
        hu = uicontrol('parent',options{2,kparent});
        options(:,kparent) = [];
    else
        hu = uicontrol;
    end
end

% mode
kmode = find(strcmp(options(1,:),'mode'));
if isempty(kmode)
    mode = 'save';
else
    mode = lower(options{2,kmode});
    options(:,kmode) = [];
end
if ~fn_ismemberstr(mode,'get,save,dir')
    error 'mode must be one of ''get'', ''save'', ''dir'''
end

% mode
kfilter = find(strcmp(options(1,:),'filter'));
if isempty(kfilter)
    filter = '*';
else
    filter = options{2,kfilter};
    options(:,kfilter) = [];
end

% set usual properties
set(hu,'style','edit','backgroundcolor',[.8 .8 .8],'enable','inactive') % by default, background is a light gray
set(hu,options{:})

% set mouse click callback
set(hu,'buttondownfcn',@(u,e)setfile(u,e,mode,filter))

%---
function setfile(u,e,mode,filter)

str = get(u,'string');
switch mode
    case 'get'
        if exist(str,'file')
            fname = fn_getfile(filter,'Select file',str);
        else
            fname = fn_getfile(filter,'Select file');
        end
    case 'save'
        if ~isempty(str)
            fname = fn_savefile(filter,'Select file',str);
        else
            fname = fn_savefile(filter,'Select file');
        end
    case 'dir'
        if exist(str,'dir')
            fname = fn_getdir('Select directory',str);
        else
            fname = fn_getdir('Select directory');
        end
end
if ~fname, return, end
set(u,'string',fname)
if ~strcmp(fname,str), fn_evalcallback(get(u,'callback'),u,e), end
