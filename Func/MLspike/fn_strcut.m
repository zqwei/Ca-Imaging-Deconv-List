function y = fn_strcut(x,c,doempty)
% function y = fn_strcut(x[,c[,doempty]])
%---
% Cut string x based on delimiter character c (default is [9 10 32], i.e.
% tab + linefeed + white space), and returns a cell array of sub-strings y.

% Thomas Deneux
% Copyright 2006-2017

if nargin<2, c = [9 10 32]; end
if nargin<3, doempty = false; end
x = x(:)';
l = length(x);

ind   = [0 find(ismember(x,c)) l+1];
if doempty
    okcut = 1:length(ind)-1;
else
    okcut = find(diff(ind)>1);
end
ncut  = length(okcut);

y   = cell(1,ncut);
for i=1:ncut
    j = okcut(i);
	y{i}   = x(ind(j)+1:ind(j+1)-1);
end
