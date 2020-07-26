function fn_movefile(pattern,rep)
% function fn_movefile(pattern,rep)
%---
% rename files in current directory using pattern and rep according to
% regexprep syntax

% Thomas Deneux
% Copyright 2012-2017

d = dir;
for i=3:length(d)
    str1 = d(i).name;
    str2 = regexprep(str1,pattern,rep);
    if ~strcmp(str1,str2)
        disp([str1 ' -> ' str2])
        movefile(str1,str2)
    end
end
