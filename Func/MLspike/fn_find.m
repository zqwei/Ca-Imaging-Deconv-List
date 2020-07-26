function idx = fn_find(fun,A,varargin)
% function idx = fn_find(fun,A[,'first|last|all|any'][,'columns|rows'])
% function idx = fn_find(A,fun[,'first|last|all|any'][,'columns|rows'])
% function idx = fn_find(x,A[,'first|last|all|any'][,'columns|rows'])
% function idx = fn_find(A[,'first|last|all|any'][,'columns|rows'])
%---
% Map function fun to elements[default]/columns/rows of A and find the
% first/last/all[default] elements that returned non-empty/non-zero
% elements (or, if 'any' flag is employed, returns a logical indicating
% whether the function returned true at least once)
%
% if no function handle is passed but any matlab variable x, the function
% fun = @(y)isequal(y,x) is used, i.e. fn_find looks for occurences of x
% inside A
%
% if only A is provided, function fun = @(y)~isempty(y) is used, i.e.
% fn_find looks for non-empty elements in A, which typically is a cell
% array
%
% See also fn_map, fn_isemptyc

% Thomas Deneux
% Copyright 2016-2017

if nargin==0, help fn_find, return, end

% Input
if ~isa(fun,'function_handle') && (nargin<2 || ischar(A))
    if nargin>=2, varargin = [{A} varargin]; end
    A = fun;
    fun = @(y)~isempty(y);
elseif isa(A,'function_handle')
    [A fun] = deal(fun,A);
elseif ~isa(fun,'function_handle')
    x = fun;
    fun = @(y)isequal(y,x);
end
mode = ''; whichindex = 'all';
for k=1:length(varargin)
    a = varargin{k};
    switch a
        case {'columns' 'rows'}
            mode = a;
        case {'first' 'last' 'all' 'any'}
            whichindex = a;
        otherwise
            error('unknown flag ''%s''',a)
    end
end
if iscell(A) && ~isempty(mode)
    error 'the ''columns'' or ''rows'' flags are not applicable on a cell array input'
end
doall = strcmp(whichindex,'all');

% Handle mode
if ~iscell(A)
    switch mode
        case ''
            A = num2cell(A);
        case 'columns'
            A = num2cell(A,1);
        case 'rows'
            A = num2cell(A,2);
    end
end
s = size(A);

% Perform operation
n = numel(A);
if doall, b = false(size(A)); else idx = []; end
if strcmp(whichindex,'last'), ord = n:-1:1; else ord = 1:n; end
for i=ord
    if feval(fun,A{i})
        if doall
            b(i) = true;
        else
            idx = i;
            break
        end
    end
end
if doall, idx = find(b); end
if strcmp(whichindex,'any'), idx = ~isempty(idx); end
