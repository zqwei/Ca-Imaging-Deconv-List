function c = fn_clustering(x,nclust)
% function c = fn_clustering(x,ncluster)
%---
% performs correlation-based clustering of data x

% Thomas Deneux
% Copyright 2012-2017


% input
switch ndims(x)
    case 2
        ismovie = false;
        x = x'; % make it space x time
    case 3
        ismovie = true;
        [nx ny nt] = size(x);
        x = reshape(x,[nx*ny nt]);
    otherwise
        error 'data must be 2-dimensional (time*space) or 3-dimensional (x*y*time)'
end
if nargin<2, ncluster = 0; end

% compute correlations
C = pdist(x,'correlation');

% dendogram
Z = linkage(C,'weighted');

% clustering
c = cluster(Z,'maxclust',nclust);
perm = randperm(nclust);
c = perm(c);

% output
if ismovie
    c = reshape(c,[nx ny]);
end