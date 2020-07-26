function [filename filterindex] = fn_getfile(varargin)
% function [filename filterindex] = fn_getfile(['READ|SAVE',][filter[,title]])
% function filename = fn_getfile('DIR',title)
% function rep = fn_getfile('REP')
% function fn_getfile('REP',rep)
%---
% returns file name with full path
% fn_getfile('REP') returns the current directory
% fn_getfile('REP',rep) sets the current directory
% as a utility, fn_getfile('cd') is going to the current directory 
% 
% See also fn_savefile

% Thomas Deneux
% Copyright 2003-2017

persistent rep

% cd to persistent directory
swd=pwd;
if isempty(rep), rep = pwd; end
try cd(rep), catch, rep = pwd; end

% Input
arg = varargin;
if (length(arg)>=1 && ischar(arg{1}) && fn_ismemberstr(arg{1},{'READ','SAVE','DIR','REP','cd'}))
    flag=arg{1}; 
    arg={arg{2:end}}; 
else
    flag='READ';
end
arg0 = arg;
if length(arg)<1 || isempty(arg{1}), arg{1}='*.*'; end
if length(arg)<2 || isempty(arg{2}), arg{2}='Select file'; end

% cd to provided path?
if fn_ismemberstr(flag,{'READ' 'SAVE'})
    fil = arg{1};
    if iscell(fil), fil = fil{1}; end
    p = fileparts(fil);
    if ~isempty(p)
        cd(p)
        fil = fn_fileparts(fil,'name');
        if iscell(arg{1}), arg{1}{1}=file; else arg{1}=fil; end
    end
end

% Matlab running in no display mode?
if ~feature('ShowFigureWindows') && ismember(flag,{'READ' 'SAVE' 'DIR'})
    disp 'fn_getfile: cannot prompt user for file or directory because Matlab is in no display mode'
    filename = 0;
    filterindex = 0;
    return
end

% different actions
switch flag
    case 'READ'
        if ischar(arg{1}) && ~any(arg{1}=='*'), arg{1} = {arg{1}, ['*' fn_fileparts(arg{1},'ext')]}; end
        [filename pathname filterindex] = uigetfile(arg{:},'MultiSelect','on');
        if iscell(filename), filename = char(filename{:}); end 
        if filename
            filename = [repmat(pathname,size(filename,1),1) filename];
            rep = pathname;
        end
    case 'SAVE'
        [filename pathname filterindex] = uiputfile(arg{:});
        if filename
            filename = fullfile(pathname,filename);
            rep = pathname;
        end
    case 'DIR'
        switch length(arg0)
            case 0
                arg = {[] 'Select directory'};
            case 1
                arg = [{[]} arg0];
            case 2
                arg = arg0([2 1]);
            otherwise
                error('too many arguments')
        end
        filename = uigetdir(arg{:});
        if filename
            rep = fileparts(filename);
        end
    case 'REP'        
        % special case: access/set the persistent directory name rep
        if nargin==1
            filename = rep;
        elseif nargin==2
            rep = varargin{2};
        end
    case 'cd'
end

% cd back to initial directory
if ~strcmpi(flag,'cd'), cd(swd), end