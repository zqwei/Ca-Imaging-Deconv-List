function varargout = fn_flags(varargin)
% function [b1 ... bn] = fn_flags({val1,...,valn},{flag1,...,flagp})
% function [b1 ... bn] = fn_flags({val1,...,valn},flag1,...,flagp)
% function [b1 ... bn] = fn_flags(val1,...,valn,{flag1,...,flagp})
% function [b1 ... bn] = fn_flags(val1,...,valn,flag)
% function x = fn_flags(...)
%---
% returns booleans (or vector thereof) mentioning which values appeared in
% the list of flags, and throws an error if a flag is not in the list of
% values 

% Thomas Deneux
% Copyright 2007-2017

% additional checks might be useful...
if iscell(varargin{1})
    values = varargin{1}; 
else
    values = varargin(1:end-1); 
end
if iscell(varargin{end})
    flags = varargin{end}; 
elseif iscell(varargin{1})
    flags = varargin(2:end); 
else
    flags = varargin(end);
end

% scan input flags
nlist = length(values);
narg  = length(flags);
x = false(1,nlist);
for i=1:narg
    str = flags{i};
    ok = false;
    for j=1:nlist
        if strcmp(str,values{j});
            x(j) = true;
            ok = true;
            break
        end
    end
    if ~ok, error('unknown flag ''%s''',str), end
end

% output
if nargout<=1
    varargout = {x};
else
    varargout = num2cell(x);
end



