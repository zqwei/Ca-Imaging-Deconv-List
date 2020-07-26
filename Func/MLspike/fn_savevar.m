function fn_savevar(fname,varargin)
% function fn_savevar(fname,var1,var2,var3...[,'-APPEND'])
%---
% save variables in a MAT file
% '-APPEND' flag will result in other variables already present in the file
% not to be removed
%
% See also fn_loadvar

% Thomas Deneux
% Copyright 2015-2017

ext = fn_fileparts(fname,'ext');
if isempty(ext), fname = [fname '.mat']; end
nvar = length(varargin);
varnames = cell(1,nvar);
anonymouschar = true;
appendflag = false;
for k=1:nvar
    str = inputname(k+1);
    val = varargin{k};
    if strcmp(val,'-APPEND'), appendflag = k; continue, end
    anonymouschar = anonymouschar && ischar(val) && isempty(str);
    if isempty(str), str = ['var' num2str(k)]; end
    varnames{k} = str;
    if iscell(val), varargin{k} = {val}; end 
end
if appendflag
    varnames(k) = [];
    varargin(k) = [];
end
tmp = [varnames; varargin];
s = struct(tmp{:}); %#ok<NASGU>
if appendflag
    save(fname,'-STRUCT','s','-MAT','-APPEND')
else
    save(fname,'-STRUCT','s','-MAT')
end

% warn if all variables were "anonymous" strings
if anonymouschar
    warning(['All variables saved to ' fname ' were anonymous character arrays. ' ...
        'Please be aware that function fn_savevar''s syntax is different from function save, ' ...
        'as it accepts variables themselves (rather than variable names) as input.'])
end
