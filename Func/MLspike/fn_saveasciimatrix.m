function fn_saveasciimatrix(a,filename)
% function fn_saveasciimatrix(a[,filename])
%---
% Save matrix in text file
%
% See also fn_readasciimatrix, fn_readdatlabview, fn_savebin, fn_savetext

% Thomas Deneux
% Copyright 2005-2017

if nargin==0, help fn_saveasciimatrix, return, end

if nargin<2, filename=fn_savefile; end
if filename==0, disp(['Could not open file ' filename]), a=[]; return, end 

fid=fopen(filename,'w');

ncol = size(a,2);
fprintf(fid,[repmat('%.16f ',1,ncol-1) '%.16f\n'],a');

fclose(fid);