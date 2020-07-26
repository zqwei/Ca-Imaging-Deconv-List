function y = fn_interleave(dim,varargin)
% function y = fn_interleave(dim,x1,x2,...[,'push'])
%---
% Similar syntax to Matlab function CAT, but interleaves the data.
% The 'push' flag results in having all dimensions more than dim 'pushed'
% rightward.
%
% Example:
%     a = reshape(1:6,2,3);
%     b = reshape(11:16,2,3);
%     fn_interleave(2,a,b)
% 
%     ans =
% 
%          1    11     3    13     5    15
%          2    12     4    14     6    16
% 
%     fn_interleave(2,a,b,'push')
% 
%     ans(:,:,1) =
% 
%          1    11
%          2    12
% 
% 
%     ans(:,:,2) =
% 
%          3    13
%          4    14
% 
% 
%     ans(:,:,3) =
% 
%          5    15
%          6    16

% Thomas Deneux
% Copyright 2012-2017

if nargin==0, help fn_interleave, return, end

% Input
dopush = false;
if ischar(varargin{end}) && strcmp(varargin{end},'push')
    dopush = true;
    varargin(end) = [];
end
x  = varargin;
nx = length(x);
siz  = size(x{1});

% Reshape 
siz2 = [siz(1:dim-1) 1 siz(dim:end)];
for i=1:nx
    xi = x{i};
    if any(size(xi)~=siz), error('size mismatch'), end
    x{i} = reshape(xi,siz2);
end

% Concatenate
y = cat(dim,x{:});

% Reshape
if ~dopush
    siz3 = [siz(1:dim-1) siz(dim)*nx siz(dim+1:end)];
    y = reshape(y,siz3);
end
