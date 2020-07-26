function fname = fn_fileext(fname,ext)
% function fname = fn_fileext(fname,ext)
%---
% Set (or replace) extension of file name

% Thomas Deneux
% Copyright 2003-2017

% input
if ext(1)~='.', ext = ['.' ext]; end

% output
fname = [fn_fileparts(fname,'noext') ext];
