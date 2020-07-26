function x = fn_readbin(fname,precision,headerlength)
% function x = fn_readbin(fname,precision,headerlength)
%---
% read binary file

% Thomas Deneux
% Copyright 2004-2017

if nargin==0, help fn_readbin, return, end

if nargin<2, precision = 'double'; end
if nargin<3, headerlength = 0; end

fid = fopen(fname,'r');
fseek(fid,headerlength,'bof'); 
x = fread(fid,Inf,precision);
fclose(fid);
