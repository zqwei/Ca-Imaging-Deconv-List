function fn_cubemesh(data,fname)
% function fn_cube(data[,fname])
%---
% creates data mesh and its texture showing the 6 faces of data 3D-object
% if called without ouptput arguments, displays it in data figure, or save it
% in data file 
% 
% faces display:       ______                                              
%     _ z            /  E   /| C                                          
%     /|        D  /______/  |                                           
%    /             |      | B|                                            
%    ---> x        | A    | /                                             
%   |              |______|/                                              
%   v y                F                                                  
%
% Input:
% - data       3D array
% - fname   file name with no extension: automatically, extensions .tri and
%           .text will be added for the mesh and texture files
%
% Output: 
% - m       cell array {vertices faces} representing the mesh
% - text    vector with values for each vertex

% Thomas Deneux
% Copyright 2010-2017

% Input
if ndims(data)~=3, error('input data must be 3-dimensional'), end
[nx ny nz] = size(data);
if nargin<2, fname = fn_savefile('Select file name for saving mesh and texture'); end

% 'Cube' vertices, faces and colors
vertices = [
    0  0  0
    nx 0  0
    0  ny 0
    nx ny 0
    
    nx 0  0
    nx ny 0
    nx 0  nz
    nx ny nz

    0  ny 0
    nx ny 0
    0  ny nz
    nx ny nz
    ];
vertices = vertices(:,[1 3 2]);
vertices(:,3) = ny-vertices(:,3);
colors = [
    1       1
    nx      1
    1       ny
    nx      ny
    
    nx      1
    nx      ny
    nx+nz-1 1
    nx+nz-1 ny

    1       ny
    nx      ny
    1       ny+nz-1
    nx      ny+nz-1
    ];
faces = [1 3 4 2; 5 6 8 7; 9 11 12 10];
faces = [faces(:,[1 2 3]); faces(:,[3 4 1])];
faces = [faces; 3 1 2; 3 2 7; 3 7 8; 3 8 11];
fn_savemesh([fname '.tri'],vertices,faces)
fn_savetexture(colors,[fname '.tex'])

% texture
text = zeros(nx+nz-1,ny+nz-1);
text(1:nx,1:ny)       = data(:,ny:-1:1,1);
text(nx:nx+nz-1,1:ny) = squeeze(data(nx,ny:-1:1,:))';
text(1:nx,ny:ny+nz-1) = squeeze(data(:,1,:));
fn_saveimg(text,[fname '.png'])   

% % (avoid too large meshes)
% nmax = max(size(data));
% thr = 80;
% if nmax>thr
%     bin = ceil(nmax/thr);
%     data = fn_bin(data,[bin bin bin]);
% end
% [nx ny nz] = size(data);
%
% % Basic coordinates
% % (vectors)
% xx = 0:nx-1;
% yy = 0:ny-1;
% zz = 0:nz-1;
% % (grids)
% ixy = ndgrid(xx,yy); ixy2 = ixy'; ixy = ixy(:); ixy2 = ixy2(:);
% iyx = ndgrid(yy,xx); iyx2 = iyx'; iyx = iyx(:); iyx2 = iyx2(:);
% ixz = ndgrid(xx,zz); ixz2 = ixz'; ixz = ixz(:); ixz2 = ixz2(:);
% izx = ndgrid(zz,xx); izx2 = izx'; izx = izx(:); izx2 = izx2(:);
% iyz = ndgrid(yy,zz); iyz2 = iyz'; iyz = iyz(:); iyz2 = iyz2(:);
% izy = ndgrid(zz,yy); izy2 = izy'; izy = izy(:); izy2 = izy2(:);
% % (blocks with extremity values)
% uz = ones(nx*ny,1)*(nz-1);
% uy = ones(nx*nz,1)*(ny-1);
% ux = ones(ny*nz,1)*(nx-1);
% 
% % Vertices
% va = [ixy  iyx2 uz*0];
% vb = [ux   iyz2 izy ];
% vc = [ixy2 iyx  uz  ];
% vd = [ux*0 iyz  izy2];
% ve = [ixz2 uy*0 izx ];
% vf = [ixz  uy   izx2];
% vertices = [va; vb; vc; vd; ve; vf];
% 
% % Faces
% % (basic squares)
% bx = [0 nx nx+1 1]; 
% by = [0 ny ny+1 1];
% bz = [0 nz nz+1 1];
% % (vectors)
% xx = (0:nx-2)';
% yy = (0:ny-2)';
% zz = (0:nz-2)';
% % (basic rows)
% rx = fn_add(xx,bx);
% ry = fn_add(yy,by);
% rz = fn_add(zz,bz);
% % (blocks with step values)
% ux = ones(nx-1,4)*nx;
% uy = ones(ny-1,4)*ny;
% uz = ones(nz-1,4)*nz;
% % (faces)
% fa = repmat(rx,ny-1,1) + kron(yy,ux);
% fb = repmat(rz,ny-1,1) + kron(yy,uz);
% fc = repmat(ry,nx-1,1) + kron(xx,uy);
% fd = repmat(ry,nz-1,1) + kron(zz,uy);
% fe = repmat(rz,nx-1,1) + kron(xx,uz);
% ff = repmat(rx,nz-1,1) + kron(zz,ux);
% % (cube)
% steps = [1 nx*ny nz*ny ny*nx ny*nz nz*nx nx*nz];
% c = cumsum(steps);
% faces = [fa+c(1); fb+c(2); fc+c(3); fd+c(4); fe+c(5); ff+c(6)];    
% 
% % Color
% ca = squeeze(data(: ,: ,1 )) ; ca = ca(:);
% cb = squeeze(data(nx,: ,: ))'; cb = cb(:);
% cc = squeeze(data(: ,: ,nz))'; cc = cc(:);
% cd = squeeze(data(1 ,: ,: )) ; cd = cd(:);
% ce = squeeze(data(: ,1 ,: ))'; ce = ce(:);
% cf = squeeze(data(: ,ny,: )) ; cf = cf(:);
% text = [ca; cb; cc; cd; ce; cf];
% 
% % Output
% if dooutput
%     m = {vertices faces};
% elseif nargin>=2
%     % (use triangular faces)
%     faces = [faces(:,[1 2 3]); faces(:,[3 4 1])];
%     fn_savemesh([fname '.tri'],vertices,faces)
%     fn_savetexture(text,[fname '.tex'])
% else
%     patch('vertices',vertices,'faces',faces,'cdata',text, ...
%         'edgealpha',0,'facecolor','interp')
% end







