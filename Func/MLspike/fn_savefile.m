function [filename filterindex] = fn_savefile(varargin)
% function [filename filterindex] = fn_savefile([filter[,title]])
%--
% synonyme de "[filename filterindex] = fn_getfile('SAVE',[filter[,title]])"
% 
% See also fn_getfile

% Thomas Deneux
% Copyright 2003-2017

[filename filterindex] = fn_getfile('SAVE',varargin{:});