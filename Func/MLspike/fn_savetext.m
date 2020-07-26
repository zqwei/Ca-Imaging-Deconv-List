function fn_savetext(a,filename)
% function fn_savetext(a[,filename])
%---
% Input:
% - a           char array
% - filename    file name
%
% See also fn_readtext, fn_readxml, fn_readasciimatrix, fn_readbin

% Thomas Deneux
% Copyright 2005-2017

if nargin==0, help fn_savetext, return, end

if nargin<2, filename=fn_savefile; end

if filename==0, disp(['Could not open file ' filename]), return, end 

fid=fopen(filename,'w');

if ~iscell(a), a = cellstr(a); end
a = fn_strrep(a,'%','%%','\','\\');
a = a(:)';
[a{2,:}] = deal('\n');
s = char([a{:}]);
fprintf(fid,s);

fclose(fid);