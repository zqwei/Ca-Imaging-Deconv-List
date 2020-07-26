function [isel jsel] = fn_subrect(a)
% function indselect = fn_subrect(a)
% function [isel jsel] = fn_subrect(a)
%---
% opens a window, displays image a, let user select a rectangle and returns
% indices corresponding to this selection

% Thomas Deneux
% Copyright 2010-2017

if nargin<1
    h = 0;
else
    h = figure;
    colormap gray
    imagesc(a(:,:,1))    
    axis image
end

r = getrect;
jsel = round(r(1))+(0:round(r(3)));
isel = round(r(2))+(0:round(r(4)));

if nargout<2
    isel = isel + size(a,1)*(jsel-1);
end

close(h)