function b = fn_eq(u,v,flag)
% function b = fn_eq(u,v,'any|all')
%---
% test 'equality' between arrays of different sizes
% ex: 
%     b = fn_eq(1:10,randi(10,7,1)) determines which pairs of indices in
%                                   two vectors correspond to matching
%                                   values
%     b = fn_eq(jet,[1 0 0],'all')  determines which indices in colormap
%                                   'jet' correspond to color red
%
% See also fn_add, bsxfun

% Thomas Deneux
% Copyright 2012-2017

b = bsxfun(@eq,u,v);
if nargin>=3
    if ~ismember(flag,{'any' 'all'}), error 'flag must be either ''any'' or ''all''', end
    s1 = size(u);
    s2 = size(v);
    n = max(length(s1),length(s2));
    s1(end+1:n) = 1; s2(end+1:n) = 1;
    for k=find(s1>1 & s2>1)
        b = feval(flag,b,k);
    end
end
    
