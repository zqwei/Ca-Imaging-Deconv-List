function str = fn_strcat(c,varargin)
% function str = fn_strcat(c)
% function str = fn_strcat(c,sep)
% function str = fn_strcat(c,left,sep,right)
%---
% Concatenate strings in cell array c, adding the separator sep between
% each element; c can also contain numbers, in which case they are
% converted to strings. 
% If there are 4 arguments, left and right are put at the left and the
% right of the final string.
% If no input is requested, display the result.

% Thomas Deneux
% Copyright 2015-2017

if nargin==0, help fn_strcat, return, end

% Input
switch nargin
    case 1
        [left sep right] = deal('');
    case 2
        sep = varargin{1};
        [left right] = deal('');
    case 3
        [left sep] = deal(varargin{:});
        right = '';
    case 4
        [left sep right] = deal(varargin{:});
    otherwise
        error 'wrong number of arguments'
end
if ~iscell(c) && ~ischar(c)
    % convert array to cell array of strings
    c = fn_num2str(c,'cell');
end
c = row(c);

% % Remove empty elements
% c(fn_isemptyc(c)) = [];

% Replace numbers by strings
for k=1:numel(c), if ~ischar(c{k}), c{k} = num2str(c{k}); end, end

% Special concatenation
[c{2,:}] = deal(sep);
c = c(1:end-1);
str = [left c{:} right];

% If no output requested, display it
if nargout==0
    disp(str)
    clear str
end
