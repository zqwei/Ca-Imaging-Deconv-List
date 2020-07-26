function str = fn_dbstack
% function fn_dbstack
%---
% displays current function name, with indent according to stack length

% Thomas Deneux
% Copyright 2007-2017


ST = dbstack;
n = 0;
for k=2:length(ST)
    if ~any(strfind(ST(k).name,'@'))
        n = n+1;
    end
end

str = repmat(' ',1,n);

if nargout==0
    disp([str ST(2).name])
    clear str
end


