function img = fn_cubeview(data,d,r)
% function [img =] fn_cubeview(data[,d[,r]])
%---
% creates an image of the 3-dimensional data where we see 3 faces of a
% cube with xy, yz and xz sides
%
% if no output is requested, displays the image in a figure and add edges
%
% faces display:       ______                                              
%     _ z            / Ypane/|                                            
%     /|           /______/Xpane                                        
%    /             |      |  |                                            
%    ---> x        |front | /                                             
%   |              |______|/                                              
%   v y                                                                   
%
% Input:
% - data    3D array
% - d       size of the side trapezes (the yz and xz faces); 
%           if d>1, size is in pixels, if d<1, it defines the ratio between
%           the side trapezes sizes and the xy size; 
%           if it is a scalar, it defines the x size, and the y size is
%           chosen so as to put perspective with and angle of 35~40
%           degrees, if it has 2 elements, it defines the x and y sizes
% - r       ratio for perspective projection (0<r<=1, r=1 is orthogonal
%           projection)
%
% Output
% - img     an image showing the cube, with a white background

% Thomas Deneux
% Copyright 2010-2017

% Input
if ndims(data)~=3, error('data bust be a 3D array'), end
[nx ny nz] = size(data);
M = max(data(:));
data = M-data;
if nargin<2, d = .3; end
if d(1)<1, d = d.*[nx ny]; end
if isscalar(d), d = [d d*2/3]; end
if nargin<3, r = 1; end
d = ceil(d);
d1 = d(1); d2 = d(2);

A = .5;

% Compute the front
% (the original image and its coordinates)
im = squeeze(data(:,:,1)); % x-y
im = [zeros(nx+2,1) [zeros(1,ny); im; zeros(1,ny)] zeros(nx+2,1)];
mask = [zeros(nx+2,1) [zeros(1,ny); ones(nx,ny); zeros(1,ny)] zeros(nx+2,1)];
x1 = -.5:nx+.5;
y1 = -.5:ny+.5;
% (the coordinates where to interpolate)
[x2 y2] = ndgrid(A/2:A:nx,A/2:A:ny);
[nx2 ny2] = size(x2);
% (interpolation)
front = interpn(x1,y1,im,x2,y2);
mask  = interpn(x1,y1,mask,x2,y2);
front = front ./ mask;
front(isnan(front)) = 0;

% Compute the X pane
% (the original image and its coordinates)
im = squeeze(data(nx,:,:))'; % z-y
im = [zeros(nz+2,1) [zeros(1,ny); im; zeros(1,ny)] zeros(nz+2,1)];
mask = [zeros(nz+2,1) [zeros(1,ny); ones(nz,ny); zeros(1,ny)] zeros(nz+2,1)];
x1 = -.5:nz+.5;
y1 = -.5:ny+.5;
% (the coordinates where to interpolate)
[xx yy] = ndgrid(A/2:A:d1,A/2:A:ny+d2);
nxp = size(xx,1);
x2 = xx*(nz/d1);
y2 = yy - (d1-xx)*(d2/d1);
y2 = y2 ./ (1 + (r-1)*xx/d1); % perspective projection
% (interpolation)
xpane = interpn(x1,y1,im,x2,y2);
mask  = interpn(x1,y1,mask,x2([1 nxp],:),y2([1 nxp],:));
xpane([1 nxp],:) = xpane([1 nxp],:) ./ mask;
xpane(isnan(xpane)) = 0;

% Compute the Y pane
% (the original image and its coordinates)
im = squeeze(data(:,1,:)); % x-z
im = [zeros(nx+2,1) [zeros(1,nz); im; zeros(1,nz)] zeros(nx+2,1)];
mask = [zeros(nx+2,1) [zeros(1,nz); ones(nx,nz); zeros(1,nz)] zeros(nx+2,1)];
x1 = -.5:nx+.5;
y1 = -.5:nz+.5;
% (the coordinates where to interpolate)
[xx yy] = ndgrid(A/2:A:nx+d1,A/2:A:d2);
nyp = size(xx,2);
y2 = (d2-yy)*(nz/d2);
x2 = xx - (d2-yy)*(d1/d2);
x2 = nx - (nx-x2) ./ (r + (1-r)*yy/d2); % perspective projection
% (interpolation)
ypane = interpn(x1,y1,im,x2,y2);
mask  = interpn(x1,y1,mask,x2(:,[1 nyp]),y2(:,[1 nyp]));
ypane(:,[1 nyp]) = ypane(:,[1 nyp]) ./ mask;
ypane(isnan(ypane)) = 0;

% Combination
img = zeros(nx2+nxp,ny2+nyp);
img(1:nx2,nyp+1:nyp+ny2) = front;
img(nx2+1:nx2+nxp,:)     = xpane;
img(:,1:nyp)             = min(img(:,1:nyp)+ypane,M);
img = M-img;

if nargout==0
    hf = gcf;
    set(hf,'color','w')
    imagesc(img')
    set(gca,'visible','off')
    axis image
    colormap gray
    clear img
end



