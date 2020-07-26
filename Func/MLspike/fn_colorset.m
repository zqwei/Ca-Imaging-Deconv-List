function [out ncol] = fn_colorset(varargin)
% function [colors ncol] = fn_colorset([setname])
% function color = fn_colorset([setname,]k)
%---
% set of colors that is larger than the Matlab default 'ColorOrder'
% property of axes
%
% if k is specified, returns the kth color, otherwise returns the set of
% colors and the length of this set
%
% available set names are 'matlab', 'newmatlab', 'plot12', 
% 'prismN' with N=4,5,6,9 or 15
% 
% See also fn_colorbyname

% Thomas Deneux
% Copyright 2008-2017

% input
setname = 'plot12';
k = [];
for i=1:nargin
    a = varargin{i};
    if ischar(a)
        setname = a;
    else
        k = a;
    end
end

% color map
tokens = regexp(setname,'^([^\d]*)(\d*)$','tokens');
setname = tokens{1}{1};
ncol = str2double(tokens{1}{2});
switch setname
    % SINGLE COLORS
    case 'ivory'
        colors = [1 1 .9]; 
    % SET OF COLORS
    case 'matlab'
        colors = [ 0 0 1; 0 0.5 0; 1 0 0; 0 0.75 0.75; 0.75 0 0.75; 0.75 0.75 0; 0.25 0.25 0.25];
    case 'newmatlab'
        colors = [0   0.4470    0.7410
            0.8500    0.3250    0.0980
            0.9290    0.6940    0.1250
            0.4940    0.1840    0.5560
            0.4660    0.6740    0.1880
            0.3010    0.7450    0.9330
            0.6350    0.0780    0.1840];
    case 'plot'
        if isempty(ncol), ncol = 12; end
        if ncol>12, error 'only 12 plot colors are available', end
        colors = [0 0 1 ; 0 .75 0 ; 1 0 0 ; ...
            0 .75 .75 ; .75 0 .75 ; .75 .75 0 ; 0 0 0 ; ...
            .75 .35 0 ; 0 1 0 ; 0 .3 0 ; .3 0 0 ; .3 0 .5];
    case 'prism'
        if isempty(ncol), ncol = 15; end
        colors = hsv(24);
        switch ncol
            case 4
                colors = colors([1 5 9 17],:);
            case 5
                colors = colors([1 5 9 17 21],:);
            case 6
                colors = colors([1 5 9 13 17 21],:);
            case 9
                colors = colors([1 4 5 9 13 14 17 1 21],:);
            case 15
                colors = colors([1 3 4 5 9 12 13 14 15 16 17 19 20 21 23],:);
            otherwise
                error 'prism sets are available for n=4,5,6,9 or 15'
        end
    otherwise
        error('unknown color set name ''%s''',setname)
end
ncol = size(colors,1);

% output
if isempty(k)
    out = colors;
else
    out = colors(1+mod(k-1,ncol),:);
end
