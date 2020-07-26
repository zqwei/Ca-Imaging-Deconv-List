function normals = fn_meshnormals(vertex,faces)
% function normals = fn_meshnormals({vertex,faces})
% function normals = fn_meshnormals(vertex,faces)

% Thomas Deneux
% Copyright 2005-2017

if nargin==1, faces=vertex{2}; vertex=vertex{1}; end

hf=figure('IntegerHandle','off','Visible','off');
ho = patch('vertices',vertex','faces',faces');
normals = -get(ho,'VertexNormals')';
normals = normals ./ repmat(sqrt(sum(normals.*normals))+0.01,3,1);
close(hf);