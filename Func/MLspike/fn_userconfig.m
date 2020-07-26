function varargout = fn_userconfig(flag,varargin)
% function [var1 var2 var3...] = fn_userconfig(flag)
% function fn_userconfig(flag,var1,var2,var3...)
% function name = fn_userconfig('configfolder|codefolder'[,filename])
%---
% Save or load variables in/from the file 
% [prefdir '/interface_options/' flag '.mat']

% Thomas Deneux
% Copyright 2015-2017

% Folder
[configfolder codefolder] = userfolders();
if fn_ismemberstr(flag,{'configfolder' 'codefolder'})
    folder = fn_switch(flag,'configfolder',configfolder,'codefolder',codefolder);
    if nargin>=2
        varargout = {fullfile(folder,varargin{:})};
    else
        varargout = {folder};
    end
    return
end

% Input
mode = fn_switch(nargin>1,'save','load');
fname = fullfile(configfolder,[flag '.mat']);

% Go
switch mode
    case 'save'
        nvar = length(varargin);
        varnames = cell(1,nvar);
        for k=1:nvar
            str = inputname(k+1);
            if isempty(str), str = ['var' num2str(k)]; end
            varnames{k} = str;
            if iscell(varargin{k}), varargin{k}={varargin{k}}; end
        end
        tmp = [varnames; varargin];
        s = struct(tmp{:}); %#ok<NASGU>
        save(fname,'-STRUCT','s')
    case 'load'
        if ~exist(fname,'file')
            disp(['no config file for flag ''' flag ''''])
            varargout = cell(1,nargout);
        else
            s = load(fname);
            varargout = struct2cell(s);
        end
end

%---
function [configfolder codefolder] = userfolders

basefolder = fullfile(prefdir,'..','brickuser');
configfolder = fullfile(basefolder,'userconfig');
codefolder = fullfile(basefolder,'usercode');
if ~exist(basefolder,'dir')
    mkdir(basefolder)
    oldconfigfolder = fullfile(prefdir,'interface_options');
    if exist(oldconfigfolder,'dir')
        movefile(oldconfigfolder,configfolder)
    else
        mkdir(configfolder)
    end
    oldcodefolder = fullfile(prefdir,'interface_usercode');
    if exist(oldcodefolder,'dir')
        movefile(oldcodefolder,codefolder)
    else
        mkdir(codefolder)
    end
end
