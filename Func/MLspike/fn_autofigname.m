function fname = fn_autofigname(hf)
% function fname = fn_autofigname(hf)
% function fn_autofigname('setfolder')
% ---
% creates an automatic name for file where to save figure hf (without
% extension however)

% Thomas Deneux
% Copyright 2012-2017

if nargin==0, help fn_autofigname, return, end

persistent savedir
if isempty(savedir) || strcmp(hf,'setfolder')
    d = fn_userconfig('fn_autofigname');
    d = uigetdir(d,'Select folder where to save figures');
    if ~ischar(d)
        error('No folder was selected!')
    elseif ~exist(d,'dir')
        error('''%s'' is not a valid folder name!',d)
    end
    fn_userconfig('fn_autofigname',d)
    savedir = d;
    if strcmp(hf,'setfolder'), return, end
end

figname = get(hf,'name');
if fn_matlabversion('newgraphics'), hfnum=get(hf,'Number'); else hfnum=hf; end
if isempty(figname), figname = ['Figure' num2str(hfnum)]; end
fname = fullfile(savedir, ... 
    [regexprep(figname,'[ |:/\\\*\+]','_')  datestr(now,'_yymmdd_HHMMSS')]);
