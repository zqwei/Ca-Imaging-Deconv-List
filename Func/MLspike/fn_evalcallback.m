function fn_evalcallback(fun,hobj,evnt)
% function fn_evalcallback(fun,hobj,evnt)

% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_evalcallback, return, end

if nargin<2, hobj = []; end
if nargin<3, evnt = []; end

if isempty(fun), return, end

switch class(fun)
    case 'char'
        evalin('base',fun)
    case 'function_handle'
        if nargin<2, evnt=[]; end
        feval(fun,hobj,evnt)
    case 'cell'
        if nargin<2, evnt=[]; end
        feval(fun{1},hobj,evnt,fun{2:end})
    otherwise
        error('graphic object callback cannot be of class ''%s''',class(fun))
end
            