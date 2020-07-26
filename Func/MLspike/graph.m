classdef graph < hgsetget
% function G = graph(nv|vvalues|vpos,edges,evalues,nvmax,nemax)
%---
% Implements a graph object. Vertices and edges can have values attached to
% them (either a scalar or a structure). 
% Vertices and edges are accessed through their index in [1 nvmax] and [1
% nemax]. When calling G.pack(), nvmax and nemax are reset to nv and ne and
% the indices of a given vertex or edge might change.

% Thomas Deneux
% Copyright 2015-2017


    properties (Dependent, SetAccess='private')
        nv              % number of vertices
        ne              % number of edges
    end
    properties (SetAccess='private')
        euclidean       % do the vertices belong to an euclidean space? 
        distance        % 'euclidean', 'correlation' or 'color'
        nvmax           % size of vconnections (>=nv)
        nemax           % size of edges (>=ne)
        vconnections    % cell array (length nvmax) of 2*n arrays (indices of edges and neighbors)
        edges           % 2*nemax array
        vvalues         % (optional) vector or structure (length nvmax), or array of vertices positions if euclidean
        vweight         % weight of vertices (add when merging), 0 for invalide vertices (length nvmax)
        evalues         % (optional) vector or structure (length nemax)
        evalid          % logical vector of length nemax and of sum ne
    end
    
    % Constructor, copy
    methods
        function G = graph(vertices,edges,evalues,nvmax,nemax,distance)
            % Set vertices
            G.euclidean = false;
            if nargin<1 || isempty(vertices) 
                n_v = 0;
            elseif isscalar(vertices)
                n_v = vertices;
            elseif isvector(vertices)
                n_v = length(vertices);
                G.vvalues = row(vertices);
            elseif isnumeric(vertices)
                n_v = size(vertices,2);
                G.euclidean = true;
                if nargin>=6
                    if ~ismember(distance,{'euclidean' 'correlation'})
                        error('unknown distance ''%s''',distance)
                    end
                    G.distance = distance;
                else
                    G.distance = 'euclidean'; 
                end
                switch G.distance
                    case 'euclidean'
                        G.vvalues = vertices;
                    case 'correlation'
                        % this is more delicate: we convert signals to
                        % z-scores, and also store their mean and std
                        m = mean(vertices,1);
                        vertices = fn_subtract(vertices,m);
                        st = sqrt(mean(vertices.^2));
                        zscores = fn_div(vertices,st); 
                        zscores(:,st==0) = 0; % z-score is zero for flat signals
                        G.vvalues = {zscores m st};
                end
            end
            G.vweight = ones(1,n_v);
            if nargin>=4 && ~isempty(nvmax) && nvmax>n_v
                G.nvmax = nvmax;
                G.vweight(nvmax) = 0;
                if ~isempty(G.vvalues)
                    if isnumeric(G.vvalues)
                        G.vvalues(:,nvmax) = 0;
                    elseif iscell(G.vvalues)
                        for i=1:length(G.vvalues)
                            G.vvalues{i}(:,nvmax) = 0;
                        end
                    else
                        error 'not implemented yet'
                    end
                end
            else
                G.nvmax = n_v;
            end
            G.vconnections = cell(1,G.nvmax);
            % Set edges
            if nargin<2 || isempty(edges)
                n_e = 0;
                G.edges = zeros(2,0);
            else
                if ~any(size(edges)==2), error 'edges must have 2 rows or 2 columns', end
                if size(edges,1)~=2, edges = edges'; end
                edges(:,~diff(edges)) = [];
                n_e = size(edges,2);
                G.edges = edges;
                if nargin>=3 && ~isempty(evalues)
                    if G.euclidean, error 'cannot attach values to the edges of an Euclidean graph (values are computed automatically as the distances between vertices)', end
                    if length(evalues)~=n_e, error 'length of evalues does not match the number of edges', end
                    G.evalues = evalues;
                elseif G.euclidean
                    G.evalues = zeros(1,n_e);
                end
                % set vertex connections
                if G.euclidean
                    switch G.distance
                        case 'euclidean'
                            V = G.vvalues;
                        case 'correlation'
                            V = G.vvalues{1};
                    end
                end
                for k=1:n_e
                    ek = edges(:,k);
                    G.vconnections{ek(1)}(:,end+1) = [k ek(2)];
                    G.vconnections{ek(2)}(:,end+1) = [k ek(1)];
                    if G.euclidean
                        % this works for both 'euclidean' and 'correlation'
                        % distances (since, in the second case, vvalues are
                        % already z-scores)
                        G.evalues(k) = norm(V(:,ek(1))-V(:,ek(2)));
                    end
                end
            end
            G.evalid = true(1,n_e);
            if nargin>=5 && ~isempty(nemax) && nemax>n_e
                G.nemax = nemax;
                G.edges(:,nemax) = 0;
                if ~isempty(G.evalues)
                    if isnumeric(G.evalues)
                        G.evalues(nemax) = 0;
                    else
                        error 'not implemented yet'
                    end
                end
                G.evalid(nemax) = false;
            else
                G.nemax = n_e;
            end
        end
        function K = copy(G)
            K = graph;
            K.euclidean = G.euclidean;
            K.distance = G.distance;
            K.nvmax = G.nvmax;
            K.nemax = G.nemax;
            K.vconnections = G.vconnections;
            K.edges = G.edges;
            K.vvalues = G.vvalues;
            K.vweight = G.vweight;
            K.evalues = G.evalues;
            K.evalid = G.evalid;
        end
    end
    
    % Basic operations
    methods
        function nv = get.nv(G)
            nv = sum(logical(G.vweight));
        end
        function ne = get.ne(G)
            ne = sum(G.evalid);
        end
        function rmvertex(G,i)
            % remove edges connecting to vertex i
            vic = G.vconnections{i};
            iedges = vic(1,:);
            G.evalid(iedges) = false;
            ineigh = vic(2,:);
            for j=ineigh
                G.vconnections{j}(:,G.vconnections{j}(2,:)==i)=[];
            end
            % remove vertex i
            G.vconnections{i} = [];
            G.vweight(i) = 0;
        end
        function [vold2new eold2new] = pack(G)
            % pack vertices
            vvalid = logical(G.vweight);
            vold2new = zeros(1,G.nvmax);
            vold2new(vvalid) = 1:G.nv;
            G.nvmax = G.nv;
            G.vconnections = G.vconnections(:,vvalid);
            if ~isempty(G.vvalues)
                if iscell(G.vvalues)
                    for i=1:length(G.vvalues), G.vvalues{i} = G.vvalues{i}(:,vvalid); end
                else
                    G.vvalues = G.vvalues(:,vvalid);
                end
            end
            G.vweight = G.vweight(vvalid);
            % pack edges
            eold2new = zeros(1,G.nemax);
            eold2new(G.evalid) = 1:G.ne;
            G.nemax = G.ne;
            G.edges = G.edges(:,G.evalid);
            if ~isempty(G.evalues), G.evalues = G.evalues(G.evalid); end
            G.evalid = true(1,G.nemax);
            % update references
            for i=1:G.nvmax
                vic = G.vconnections{i};
                G.vconnections{i} = [eold2new(vic(1,:)); vold2new(vic(2,:))]; 
            end                
            G.edges = vold2new(G.edges);
            % output
            if nargout==0, clear vold2new, end
        end
    end
    
    % Decimation
    methods
        function merge(G,i,j)
            % replace vertix i by the merge, remove vertex j
            wij = G.vweight(i)+G.vweight(j);
            if G.euclidean
                switch G.distance
                    case 'euclidean'
                        valuei = G.vvalues(:,i)*(G.vweight(i)/wij)+G.vvalues(:,j)*(G.vweight(j)/wij);
                        G.vvalues(:,i) = valuei;
                        G.vvalues(:,j) = 0;
                    case 'correlation'
                        % mean
                        w1 = G.vweight(i)/wij;
                        w2 = (1-w1);
                        m1 = G.vvalues{2}(i)*w1;
                        m2 = G.vvalues{2}(j)*w2;
                        G.vvalues{2}(i) = m1 + m2;
                        G.vvalues{2}(j) = 0;
                        % mean-subtracted signal
                        st1 = G.vvalues{3}(i)*w1;
                        st2 = G.vvalues{3}(j)*w2;
                        valuei = G.vvalues{1}(:,i)*st1+G.vvalues{1}(:,j)*st2;
                        % standard deviation
                        st = sqrt(mean(valuei.^2));
                        G.vvalues{3}(i) = st;
                        G.vvalues{3}(j) = 0;
                        % z-score
                        if st>0
                            valuei = valuei/st;
                        else
                            valuei = 0; % z-score is 0 for flat signals
                        end
                        G.vvalues{1}(:,i) = valuei;
                        G.vvalues{1}(:,j) = 0;                        
                end
            elseif ~isempty(G.vvalues)
                error 'cannot determine how to set the value of merged vertex for non-euclidean graph'
            end
            G.vweight(i) = wij; % this line has to be after the definition of valuei above
            G.vweight(j) = 0;   % idem
           % edges and neighbors connected to i or j
            vic = G.vconnections{i};
            iedges = vic(1,:);
            ineigh = vic(2,:);
            vjc = G.vconnections{j};
            G.vconnections{j} = [];
            jedges = vjc(1,:);
            jneigh = vjc(2,:);
            % remove the i-j connection and redundant connections
            oki = (ineigh~=j);
            % (the 3 lines below do the same as
            % 'rmj = ismember(jneigh,ineigh);' but are much faster
            test = false(1,G.nvmax);
            test(ineigh) = true;
            rmj = test(jneigh);
            okj = (jneigh~=i) & ~rmj;
            G.vconnections{i} = [vic(:,oki) vjc(:,okj)];
            rmedges = [iedges(~oki) jedges(~okj)]; 
            G.evalid(rmedges) = false;
            G.edges(:,rmedges) = 0;
            if G.euclidean, G.evalues(:,rmedges) = Inf; end
            % update the neighbors, update distances
            if G.euclidean
                if strcmp(G.distance,'euclidean'), V = G.vvalues; else V = G.vvalues{1}; end
                for e = vic(:,oki) % e is [edge index; neighbor index]
                    G.evalues(e(1)) = norm(valuei-V(:,e(2)));
                end
            end
            for e = vjc(:,okj)
                k = e(1); % edge index
                h = e(2); % neighbor vertec index
                % (replace j by i in the edge definition)
                if G.edges(1,k)==j
                    G.edges(1,k)=i;
                else
                    G.edges(2,k)=i;
                end
                % (replace j by i in the neighbor's neighbors)
                G.vconnections{h}(2,G.vconnections{h}(2,:)==j)=i;
                % (update distance)
                if G.euclidean
                    G.evalues(k) = norm(valuei-V(:,h));
                end
            end
            for h = jneigh(rmj)
                G.vconnections{h}(:,G.vconnections{h}(2,:)==j)=[];
            end
        end
        function [tree cdist]=decimate(G,n,tree,cdist)
            if nargout>0
                if nargin<3
                    if G.nv~=G.nvmax, error 'pack graph first', end
                    tree = [1:G.nvmax; zeros(1,G.nvmax)];
                else
                    if G.nvmax~=length(tree) || ~all(tree(:)<=G.nvmax) || ~all(ismember(find(G.vweight),tree(1,:)))
                        error 'starting tree does not match current graph'
                    end
                end
            end
            % loop until reaching target number of vertices
            if n>0, target=n; else target=G.nv+n; end
            target = max(target,1);
            n_v = G.nv;
            while n_v>target
                [m k] = min(G.evalues); 
                ek = G.edges(:,k);
                G.merge(min(ek),max(ek));
                if nargout>=1, tree(:,max(ek))=[min(ek); n_v]; end
                n_v = n_v-1;
                if nargout>=2, cdist(G.nvmax-n_v)=m; end
            end
        end
    end
    
    % Display
    methods
        function A = matrix(G)
            if G.nvmax<=10
                A = zeros(G.nvnvmax);
            else
                A = sparse(G.nvnvmax,G.nvnvmax);
            end
            for i=1:G.nvnvmax
                vic = G.vconnections{i};
                for idx=1:length(vic)
                    k = vic(idx);
                    ek = G.edges(:,k);
                    if ek(1)==i, j=ek(2); else j=ek(1); end
                    if i<j
                        if isempty(G.evalues)
                            A(i,j) = 1; 
                        else
                            A(i,j) = G.evalues(k);
                        end
                    end
                end
            end
        end
        function hl = plot(G,flag)
            if ~G.euclidean, error 'only euclidean graph can be plot', end
            if nargin<2, flag = 'numbers'; end
            tmp = ishold;  
            if strcmp(G.distance,'euclidean'), V = G.vvalues; else V = G.vvalues{1}; end
            z = G.edges(:,G.evalid);
            n_e = size(z,2);
            if n_e>0
                x = zeros(2,2,n_e);
                for i=1:n_e
                    x(:,:,i) = V(1:2,z(:,i));
                end
                if n_e>1, x(:,3,:) = NaN; end
                hl(2) = plot(x(1,:),x(2,:));
                hold on
            end
            vvalid = logical(G.vweight);
            x = V(1:2,vvalid);
            hl(1) = scatter(x(1,:),x(2,:),G.vweight(vvalid));
            hold(fn_switch(tmp))
            switch flag
                case 'numbers'
                    for i=find(vvalid)
                        text(V(1,i),V(2,i),num2str(i))
                    end
                case 'o'
                    line(V(1,vvalid),V(2,vvalid),'linestyle','none','marker','o', ...
                        'markerfacecolor','w')
            end
        end
    end
end
