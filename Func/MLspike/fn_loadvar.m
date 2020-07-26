function varargout = fn_loadvar(fname,varargin)
% function [var1 var2 var3...] = fn_loadvar([fname[,varname1,...]])
%---
% Load variables from a MAT file.
%
% See also fn_savevar

% Thomas Deneux
% Copyright 2015-2017

if nargin<1, fname = fn_getfile; if ~fname, return, end, end
if ~exist(fname,'file')
    fnamemat = [fname '.mat'];
    if exist(fnamemat,'file')
        fname = fnamemat;
    elseif any(fname=='*')
        fname = fn_getfile(fname);
        if isequal(fname,0), [varargout{1:nargout}] = deal([]); return, end
    else
        error('Neither file ''%s'' or ''%s'' exists.',fname,fnamemat)
    end
end

if isempty(varargin)
    s = load(fname,'-MAT');
    if length(fieldnames(s))~=max(nargout,1)
        if nargout<=1
            disp 'fn_loadvar: multiple variable converted to a single structure'
            varargout = {s};
        else
            error 'number of output arguments does not match number of variables saved in MAT file'
        end
    else
        varargout = struct2cell(s);
    end
else
    if iscell(varargin{1})
        varnames = varargin;
    else
        varnames = varargin;
    end
    if length(varnames)~=max(nargout,1)
        error 'number of output arguments does not match number of variables'
    end
    varargout = cell(1,max(nargout,1));
    for i=1:max(nargout,1)
        s = load(fname,varnames{i},'-MAT');
        varargout{i} = s.(varnames{i});
    end
end
