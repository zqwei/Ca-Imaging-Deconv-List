function pargout=fn_meshplot(varargin)
% function ho=fn_meshplot(vertex, faces[, vcolor])
% function ho=fn_meshplot({vertex, faces}[, vcolor])

% Thomas Deneux
% Copyright 2005-2017

% Input
if nargin==0
    vertex = fn_readmesh;
elseif iscell(varargin{1})
    mesh = varargin{1};
    vertex = mesh{1};
    faces = mesh{2};
    if nargin>1, vcolor = varargin{2}; end
else
    vertex = varargin{1};
    faces = varargin{2};
    if nargin>2, vcolor = varargin{3}; end    
end

if size(vertex,1)~=3
    if size(vertex,2)==3, vertex=vertex'; else error('vertex must be nx3 or 3xn'); end
end
if size(faces,1)~=3
    if size(faces,2)==3, faces=faces'; else error('faces must be nx3 or 3xn'); end
end
if any(faces-floor(faces) & faces<1 & faces>size(vertex,2))
    error('faces must contain positive integer values <= length(vertex)')
end

nvertex = size(vertex,2);     % #vertices
[ne nfaces] = size(faces); % #faces, #edges/cell

if ~exist('vcolor') vcolor=ones(nvertex,1); end
   
% Display
ho=patch('Vertices',vertex','Faces',faces','FaceVertexCdata',vcolor,...
    'LineStyle','none',...
    'CDataMapping','scaled','FaceColor','interp',...
    'AmbientStrength', 0.6, 'FaceLighting', 'phong');

if ~isempty(get(gca,'Tag')) return; end

set(gca,'Tag','fn_meshplot')
cameratoolbar
%cameratoolbar setmode orbit
camorbit(0,-90)
% camorbit(-135,0)
% camlight
% camorbit(180,0)
% camlight
axis equal

if nargout>0, pargout={ho}; end
        