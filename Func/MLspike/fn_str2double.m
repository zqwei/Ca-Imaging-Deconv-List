function y = fn_str2double(x,donan)
% function y = fn_str2double(x[,donan=true])
%---
% scan character array x to read a double... only if is really a character
% array!!
%
% See also fn_num2str

% Thomas Deneux
% Copyright 2007-2017

if nargin<2, donan = true; end

xiscell = iscell(x);
if ~xiscell, x = {x}; end

y = x;
for i=1:numel(y)
    if ischar(x{i})
        yi = str2double(x{i});
        if donan || ~isnan(yi) || strcmpi(x{i},'NaN'), y{i} = yi; end 
    end
end

if ~xiscell, y = y{1}; end
