function filename = fn_getdir(varargin)
% function dirname = fn_getdir(title[,dirname])
%--
% synonyme de "filename = fn_getfile('DIR',title)"

% Thomas Deneux
% Copyright 2003-2017

filename = fn_getfile('DIR',varargin{:});