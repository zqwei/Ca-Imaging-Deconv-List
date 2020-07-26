function y = fn_ls(varargin)
% function y = fn_ls([[folder,]pattern])
%---
% List files inside directory

% Thomas Deneux
% Copyright 2009-2017

if nargin==0
    y = dir;
else
    y = dir(fullfile(varargin{:}));
end
y = {y.name};