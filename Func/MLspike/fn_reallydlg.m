function b = fn_reallydlg(varargin)
% function b = fn_reallydlg(line1,line2,..)
%--
% This is a shortcut for using Matlab questdlg function.
% returns true if 'Yes' has been answered
% argument can be one or several string or cell array of strings
% 
% See also fn_dialog_questandmem

% Thomas Deneux
% Copyright 2009-2017

if nargin==0, help fn_reallydlg, return, end

for i=1:nargin
    if ~iscell(varargin{i}), varargin{i}={varargin{i}}; end
end
question = [varargin{:}];
answer = questdlg(question,'warning','Yes','No','No');
b = strcmp(answer,'Yes');
