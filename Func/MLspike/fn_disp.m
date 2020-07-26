function fn_disp(varargin)
% function fn_disp(varargin)
%---
% displays each argument in an improved ergonomic way

% Thomas Deneux
% Copyright 2004-2017

for i=1:nargin
    a = varargin{i};
    disp(a)
    if isnumeric(a)
        fprintf('\b')
    end
end