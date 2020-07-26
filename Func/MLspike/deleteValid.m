function deleteValid(varargin)
% function deleteValid(obj1,obj2,...)
%---
% Delete valid objects among the list of objects obj.
%
% See also disableListener

% Thomas Deneux
% Copyright 2015-2017

for i=1:nargin
    obj = varargin{i};
    if isempty(obj), return, end
    if isstruct(obj), obj = struct2cell(obj); end
    if iscell(obj), deleteValid(obj{:}), return, end
    if isobject(obj)
        % objects
        delete(obj)
    else
        % graphic handles
        obj = row(obj);
        delete(obj(ishandle(obj) & obj~=0))
    end
end

