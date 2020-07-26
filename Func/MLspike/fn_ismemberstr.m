function c = fn_ismemberstr(a,b,doerrorflag)
% function c = fn_ismemberstr(a,b[,'doerror'])
%---
% Same as ismember(a,b), but faster!!, for cell arrays of strings only.
% For easier programming, the set of strings b can also be defined as a
% single string with sub-strings separated by commas.
%
% If no output argument is requested and flag 'doerror' is used, the
% function generates an error if any element of a does not match an element
% in b.

% Thomas Deneux
% Copyright 2007-2017

if ~iscell(a)
    a = {a}; 
end
if ~iscell(b)
    b = fn_strcut(b,','); 
end
if nargin==3
    if ~strcmp(doerrorflag,'doerror') || nargout>0, error argument, end
    doerror = true;
else
    doerror = false;
end
        

c = false(size(a));
if isempty(a), return, end

% convert numeric values into char
if ~ischar(a{1})
    a = fn_map(@char,a,'cell'); 
    b = fn_map(@char,b,'cell'); 
end


for i=1:numel(a)
    ai = a(i);
    for j=1:numel(b)
        if strcmp(ai,b{j}), c(i)=true; break, end
    end
end

if doerror
    if ~all(c)
        if isscalar(a)
            msg = ['unknown flag ''' a{1} ''''];
        else
            msg = ['unknown flag(s)'];
        end
        msg = [msg ', possible values are ''' fn_strcat(b,''', ''') ''''];
        error(msg)
    end
    clear c
end
