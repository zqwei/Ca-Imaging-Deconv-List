function varargout = fn_fileparts(f,varargin)
% function [out1 out2...] = fn_fileparts(fname,flag1,flag2,...[,'strict'])
%---
%
% Input:
% - fname       file name
% - flag        one of the possible flags below, or a cell array of flags,
%               in which case fn_fileparts is applied iteratively using
%               each value as flag successively
%   'path'      returns the path (fn_filename('a/b/','path') returns 'a')
%   'base'      removes the path and the extension (fn_filename('a/b.c','base')
%               returns 'b') 
%   'ext'       returns the extension (fn_filename('a/b.c','ext') returns '.c')
%   'extnodot'  returns the extension without dot (fn_filename('a/b.c','extnodot') returns 'c')
%   'name'      removes the path (fn_filename('a/b/','name') returns 'b',
%               fn_filename('a/b.c','name') returns 'b.c') 
%   'noext'     removes the extention (fn_filename('a/b.c','noext') returns
%               'a/b') 
%   ''          only removes trailing '/' characters
% - 'strict'    consider that the base and extension of 'a.b.c' are 'a' and
%               'b.c' respectively, rather than 'a.b' and 'c'

% Thomas Deneux
% Copyright 2003-2017

if nargin==0, help fn_fileparts, return, end

% check
narg = length(varargin);
if max(1,nargout)~=narg
    error 'number of outputs does not match number of flags'
end

% multiple inputs
if iscell(f)
    if narg>1, error 'not implemented yet', end
    out = cell(size(f));
    for i=1:numel(f), out{i} = fn_fileparts(f{i},varargin{:}); end
    varargout = {out};
    return
end

% strict?
flags = varargin;
kstrict = strcmp(flags,'strict');
dostrict = any(kstrict);
if dostrict
    flags(kstrict) = []; narg = narg-1;
end


% initial decomposition
f = char(f);
while ~isempty(f) && f(end)=='/', f(end)=[]; end
[p b e] = fileparts(f);
if dostrict
    pt = find(b=='.',1,'first');
    if ~isempty(pt)
        e = [b(pt:end) e]; 
        b = b(1:pt-1);
    end
end

% outputs
varargout = cell(1,narg);
for k=1:narg
    flagk = flags{k};
    if iscell(flagk)
        flagknext = flagk(2:end);
        flagk = flagk{1};
    else
        flagknext = {};
    end
    switch flagk
        case ''
            out = f;
        case {'dir' 'path'}
            out = p;
        case 'base'
            out = b;
        case 'ext'
            out = e;
        case 'extnodot'
            out = e;
            if ~isempty(out), out(1)=[]; end
        case 'name'
            out = [b e];
        case 'noext'
            out = fullfile(p,b);
        otherwise
            error('unknown flag ''%s''',flag)
    end
    if ~isempty(flagknext), out = fn_fileparts(out,flagknext); end
    varargout{k} = out;
end
