function a=fn_readasciimatrix(filename,nheaders)
% function a=fn_readasciimatrix(filename,nheaders)
% 
% load a matrix from an ascii file with format like :
%   #blah blah
%   et reblah 45 blah
%   1.2 3 5.5
%   4   0 0 
%   3   3 14
% Empty matrix is returned if file does not exist or if there is no numeric
% content at any line begin.
% There is no verification that each row is the same length.
% Only spaces are considered as separators between columns (use Matlab
% csvread to read comma-separated files!).
%
% if 'nheader' is specified, first nheaders lines are skipped anyway
%
% See also fn_saveasciimatrix, fn_readdatlabview, fn_readtext, fn_readbin

% Thomas Deneux
% Copyright 2005-2017

if nargin==0, filename=fn_getfile; end
if filename==0, disp(['Could not open file ' filename]), a=[]; return, end 

fid=fopen(deblank(filename),'r');

if nargin>=2
    for i=1:nheaders
        tline = fgetl(fid); 
    end
end

m=0;
while m==0
    fpos=ftell(fid);
    tline = fgetl(fid);
    if ~ischar(tline), disp([filename ' : wrong format for ascii matrix']), a=[]; return, end 
    tline = sscanf(tline,'%f',inf);
    m = length(tline);
end
fseek(fid,fpos,-1);
a=fscanf(fid,'%f',[m inf])';
fclose(fid);

