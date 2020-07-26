function varargout = fn_get(h,varargin)
% function x = fn_get(h,f[,'cell|struct'])
% function x = fn_get(h,f1,f2,...)
% function [x1 x2 ...] = fn_get(...)
%--- 
% Returns values for properties f of objects with handle h
% output is a cell array or a structure according to flag.
% If the flag output is not specified, output is a cell array if only one
% property is requested, and a structure if more than one.
% 
% fn_get also has some heuristics to get properties that do not exist:
% - properties 'xdata', 'ydata' and 'zdata' for object of type 'text' are
%   defined from its property 'position'
% 
% 
% See also fn_set

% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_get, return, end

% Input
if nargin==2
    f = cellstr(varargin{1});
    flag = fn_switch(isscalar(f),'cell','struct');
elseif nargin==3 && fn_ismemberstr(varargin{2},{'cell' 'struct' 'char'})
    f = cellstr(varargin{1});
    flag = varargin{2};
else
    f = varargin;
    flag = 'struct';
end
if ~iscell(f)
    f = cellstr(f);
end
nobj   = numel(h);
nfield = length(f);

% Get properties
x = cell(nobj,nfield);
ok = true;
for i=1:nobj
    for j=1:nfield
        if isprop(h(i),f{j})
            x{i,j} = get(h(i),f{j});
        elseif fn_ismemberstr(f{j},{'xdata' 'ydata' 'zdata'}) &&  strcmp(get(h(i),'type'),'text')
            % some heuristics to 'guess' the undefined property
            pos = get(h(i),'pos');
            x{i,j} = pos(fn_switch(f{j}(1),'x',1,'y',2,'z',3));
        elseif strcmp(f{j},'appdata')
            x{i,j} = getappdata(h(i));
        else
            ok = false;
        end
    end
end
if ~ok
    disp 'some properties were not found'
end

% Output
if nargout>1
    if nobj==1 || nfield==1
        if nargout~=nobj*nfield, error 'number of outputs does not match', end
        varargout = x;
    else
        if nargout~=nobj, error 'number of outputs does not match', end
        x = cell2struct(x,f,2);
        varargout = num2cell(x);
    end
else
    switch flag
        case 'cell'
            % output is already a cell array
        case 'struct'
            x = cell2struct(x,f,2);
        otherwise
            error 'unknown flag'
            %     case 'array'
            %         if ~isscalar(x), error 'fn_get cannot output a string since more than one properties have been accessed', end
            %         x = x{1};
    end
    varargout = {x};
end
