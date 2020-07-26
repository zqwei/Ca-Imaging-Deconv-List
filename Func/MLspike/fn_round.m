function x = fn_round(x,y,mode)
% function x = fn_round(x[,y[,'floor|ceil'])
%---
% eliminate floating point error
% rounds to the nearest multiple of y if a second argument is given

% Thomas Deneux
% Copyright 2009-2017

if nargin==0, help fn_round, end

s = size(x);
if nargin>=2
    if nargin<3, mode = 'round'; end
    x = feval(mode,x/y)*y;
end

switch class(x)
    case 'double'
        x = str2num(num2str(x,'%.14g ')); %#ok<ST2NM>
    case 'single'
        x = str2num(num2str(x,'%.7g ')); %#ok<ST2NM>
    otherwise
        disp('strange usage of fn_round')
end
x = reshape(x,s);

