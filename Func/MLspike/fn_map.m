function B = fn_map(fun,A,varargin)
% function B = fn_map(fun,A[,'columns|rows'][,'array|cell|arraydirect'][,errorval])
% function B = fn_map(A,fun,...)
%---
% map function 'fun' to elements [default] / columns / rows of A
%
% output an array or a cell array depending on the flag; if no flag is
% specified, output a vector if all returned values are scalar, a cell
% otherwise; 'arraydirect' flag indicates that all values are expected to
% be scalar, therefore no cell array is created, which saves the time of
% calling cell2mat function
%
% if errorval is specified, errors are caught and the value errorval is
% returned in case of an error
%
% See also fn_isemptyc, fn_itemlengths, fn_find

% Thomas Deneux
% Copyright 2006-2017

if nargin==0, help fn_map, return, end

% Input
if ~isa(fun,'function_handle')
    [A fun] = deal(fun,A);
end
mode = ''; outtype = 'auto'; manageerror = false; doarraydirect = false;
for k=1:length(varargin)
    a = varargin{k};
    if ischar(a)
        switch a
            case {'columns' 'rows'}
                mode = a;
            case {'array' 'cell'}
                outtype = a;
            case 'arraydirect'
                doarraydirect = true;
            otherwise
                manageerror = true;
                errorval = a;
        end
    else
        manageerror = true;
        errorval = a;
    end
end

% Handle mode
switch mode
    case ''
        if ~iscell(A), A = num2cell(A); end
    case 'columns'
        A = num2cell(A,1);
    case 'rows'
        A = num2cell(A,2);
end
s = size(A);

% A empty?
if isempty(A)
    dooutput = (nargout==1);
    if ~dooutput, return, end
    if strcmp(outtype,'cell')
        B = cell(size(A));
    else
        B = zeros(size(A));
    end
    return
end
    
% Any output?
try
    b = fun(A{1});
    dooutput = true;
catch ME
    if strcmp(ME.identifier,'MATLAB:maxlhs')
        dooutput = false;
    elseif manageerror
        dooutput = true;
    else
        rethrow(ME)
    end
end
if doarraydirect
    if ~isscalar(b)
        if manageerror, b = errorval; else error 'values are expected to be scalar', end
    end
    if isnumeric(b)
        B = zeros(s,class(b));
        B(1) = b;
    elseif islogical(b)
        B = false(s);
        B(1) = b;
    else
        B = repmat(b,s);
    end
elseif dooutput
    B = cell(s); 
    B{1} = b; % no need to re-compute B{1}
end

% Perform operation
n = numel(A);
for i=1+dooutput:n
    if manageerror
        if ~dooutput, error 'fn_map cannot manage errors if no output', end
        try
            b = fun(A{i});
            if doarraydirect, B(i) = b; else B{i} = b; end
        catch %#ok<CTCH>
            b = errorval;
            if doarraydirect, B(i) = b; else B{i} = b; end
        end
    else
        if dooutput
            b = fun(A{i});
            if doarraydirect, B(i) = b; else B{i} = b; end
        else
            feval(fun,A{i});
        end
    end
end

% Output: try not to return a cell
if ~dooutput, return, end
if doarraydirect, return, end % already an array
switch outtype
    case 'array'
        doarray = true;
    case 'cell'
        doarray = false;
    case 'auto'
        doarray = true;
        for i=1:n
            if ~isscalar(B{i}), doarray = false; break; end
        end
end
if dooutput && doarray
    try
        B = cell2mat(B);
        if isempty(A), B = reshape(B,size(A)); end % cell2mat applied to empty cell array A returned [] instead of zeros(size(A)) 
    catch
        for i=2:n, B{i} = cast(B{i},'like',B{1}); end
        B = cell2mat(B);
    end
end