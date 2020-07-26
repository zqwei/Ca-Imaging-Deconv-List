function ha = fn_parentaxes(obj)
% function ha = fn_parentaxes(obj)
%---
% returns the axes that contains object obj by recursively getting its
% parents

% Thomas Deneux
% Copyright 2015-2017

ha = obj;
while ~strcmp(get(ha,'type'),'axes'), ha = get(ha,'parent'); end
