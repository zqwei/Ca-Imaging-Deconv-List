function [colornum colorname] = fn_colorbyname(colorval,flag)
% function [colornum colorname] = fn_colorbyname(colorval[,'strict'])
%---
% Returns numerical value and name if it exists of color, passed either as
% a value or a string.
% If colorval does not represent a color, generates an error only if the
% 'strict' flag is used (otherwise it returns empty arrays).
%
% Examples:
%  [num name] = fn_colorbyname('r')        returns [1 0 0] and 'red'
%  [num name] = fn_colorbyname([0 0 0])    returns [0 0 0] and 'black'
%  [num name] = fn_colorbyname([.1 .3 .4]) returns [.1 .3 .4] and ''
%
% See also fn_colorset

% Thomas Deneux
% Copyright 2015-2017

% input
dostrict = (nargin>=2) && strcmp(flag,'strict');

% known colors
colnum = [0 0 0; 1 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1];
colstr = {'black' 'white' 'red' 'green' 'blue' 'yellow' 'magenta' 'cyan'};
colnik = 'kwrgbymc';

% get color by name or value
colornum = [];
colorname = '';
if isnumeric(colorval) && isvector(colorval) && length(colorval)==3
    colornum = row(colorval);
    idx = find(all(fn_eq(colornum,colnum),2));
    if ~isempty(idx), colorname = colstr{idx}; end
elseif ischar(colorval)
    if isscalar(colorval)
        idx = find(colorval==colnik);
    else
        idx = find(strcmp(colorval,colstr));
    end
    if ~isempty(idx)
        colornum = colnum(idx,:);
        colorname = colstr{idx};
    end
end

% generate error if needed
if dostrict && (isempty(colornum) || ~all(colornum>=0 & colornum<=1))
    error 'argument is not a valid color'
end




