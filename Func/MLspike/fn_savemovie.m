function M = fn_savemovie(a,varargin)
% function M = fn_savemovie(a[,fname][,clip][,fps][,zoom][,map][,hf])
% function M = fn_savemovie(a[,'fname',fname],['compression',compression],...)
%---
% Input:
% - a       x-y-t array (be aware Matlab convention for images is y-x)
%           or x-y-c-t for true colors (c stands for the 3 color channels,
%           values should be in [0 1] 
% - fname   file name (movie is saved in file only if specified) [default =
%           30]
% - clip    a 2-values vector, or 'fit', or '?SD'
% - fps     frames per second
% - zoom    zooming value, according to which the movie is either
%           interpolated (zoom>0) or binned (0<zoom<1) or enlarged with
%           "big pixels" (zoom<-1) 
% - map     nx3 array for the colormap [default = gray(256)]
% - hf      figure handle (if specified, the movie is played in figure)
%
% Note that arguments can be passed in any order, except the first; if
% there is ambiguity, the function tries to guess which value was entered
% (for example a scalar value will be assigned to 'fps' if it is >=5, and to
% 'zoom' if it is <5); in order to de-ambiguate, it is possible to preced
% the value by a flag.
% e.g. fn_savemovie(rand(3,4,25),'fname','test.avi','zoom',10)
% 
% Output
% - M       movie frames (Matlab format)
%
% See also fn_readmovie, fn_movie

% Thomas Deneux
% Copyright 2004-2017

if nargin<1, help fn_savemovie, return, end

% Input
if (ndims(a)==4)
    truecolors = true;
    [ni nj nc nt] = size(a);
    if nc~=3
        if nc==1
            truecolors = false;
        elseif nt==3
            a = permute(a,[1 2 4 3]);
            [ni nj nc nt] = size(a);
        else            
            error('if data is 4D, third dimension should be 3 (true colors)')
        end
    end
else
    truecolors = false;
    [ni nj nt] = size(a);
    nc = 1;
    a = reshape(a,[ni nj nc nt]);
end
i = 1;
fname = []; clip = 'fit'; fps = 30; zoom = 1; map = gray(256); hf = [];
compression = 'none';
while i<=length(varargin)
    x = varargin{i}; i=i+1;
    if ischar(x)
        if strcmp(x,'fit') || any(findstr(clip,'%iSD'))
            clip = x;
        else 
            switch x
                case 'fname'
                    fname = varargin{i}; i=i+1;
                case 'clip'
                    clip = varargin{i}; i=i+1;
                case 'fps'
                    fps = varargin{i}; i=i+1;
                case 'zoom'
                    zoom = varargin{i}; i=i+1;
                case 'map'
                    map = varargin{i}; i=i+1;
                case 'hf'
                    hf  = varargin{i}; i=i+1;
                case 'compression'
                    compression = varargin{i}; i=i+1;
                case 'i420'
                    compression = x;
                otherwise
                    if isempty(fname)
                        fname = x;
                    else
                        map = feval(x,256);
                    end
            end
        end
    elseif isscalar(x)
        if ishandle(x)
            switch get(x,'type')
                case 'figure'
                    hf = x;
                case 'axes'
                    axes(x)
                    hf = get(x,'parent');
                otherwise
                    error('graphic handle must be figure or axes')
            end
        elseif x>5
            fps = x;
        else
            zoom = x;
        end
    elseif isvector(x) && length(x)==2
        clip = x;
    elseif size(x,2)==3
        map = x;
    else
        error('argument error')
    end
end
if nargout==0 && isempty(fname) && isempty(hf)
    fname = fn_savefile('*.avi','Select file to save movie.');
    if ~fname, disp('canceled'), return, end
end

% clipping and color map
disp('rescale'), drawnow
if ~truecolors
    if ischar(clip)
        if strcmp(clip,'fit')
            clip = [min(a(:)) max(a(:))];
        elseif findstr(clip,'SD')
            nsd = sscanf(clip,'%iSD');
            m = mean(a(:));
            sd = std(a(:));
            clip = [m-nsd*sd m+nsd*sd];
        else
            error('clipping flag ''%s'' is not recognized',clip)
        end
    else
        if length(clip(:))~=2
            error('clipping value is not correct')
        end
    end
end
if truecolors
    ncol = 256;
else
    ncol = size(map,1);
    a = (a-clip(1)) * ((ncol-1)/(clip(2)-clip(1)));
    a = min(max(a+1,1),ncol);
end

% zoom parameters
if zoom<0
    % special: change dimension, but without interpolation; zoom must be of
    % the form -N or -1/N
    if zoom<-1, N=-zoom; else N=-1/zoom; end
    if ~mod(N,1)==0, error('negative zoom factor must be of the form -N or -1/N'), end
    if zoom<-1
        a = reshape(a,1,ni,1,nj,nc,nt);
        a = repmat(a,[N 1 N 1 1]);
        a = reshape(a,ni*N,nj*N,nc,nt);
    else
        a = fn_bin(a,[N N 1 1]);
    end
    [ni nj nc nt] = size(a);
    zoom = 1;
end
if zoom~=1
    if truecolors
        error('zoom>0 not implemented yet for true colors')
    end
    if zoom<1
        % necessitate low-pass filtering before interpolation
        sigma = 1/(2*zoom);
        h = fspecial('gaussian',5*ceil(sigma),sigma);
    elseif ~mod(zoom,1)
        disp 'zoom>1 will perform interpolation, use negative zoom value to enlarge without interpolation'
    end
    [xx yy] = meshgrid(1:nj,1:ni); 
    [xx2 yy2] = meshgrid(1:1/zoom:nj,1:1/zoom:ni);
    fn_progress('converting frames',nt)
else
    disp('converting frames'), drawnow
end

M = struct('cdata',cell(1,nt),'colormap',cell(1,nt));
if isempty(hf)
    % convert to frames
    for i=1:nt
        fr = permute(a(:,:,:,i),[2 1 3]);
        if ~isa(fr,'uint8'), fr = double(fr); end
        if zoom~=1
            fn_progress(i);
            if zoom<1, fr = filter2(h,fr); end
            fr = interp2(xx,yy,fr,xx2,yy2,'*spline');
            fr = min(max(fr,1),ncol);
        end
        M(i) = im2frame(fr,map);
    end
else
    % display & convert to frames
    figure(hf)
    if truecolors
        img = imagesc(zeros(nj,ni,3));
    else
        colormap(map)
        img = imagesc(zeros(nj,ni),clip);
    end
    set(gca,'visible','off')
    set(img,'cdatamapping','direct')
    axis image
    for i=1:nt
        fr = permute(a(:,:,:,i),[2 1 3]);
        set(img,'cdata',fr)%, M={fr img clip}; return
        %colorbar
        %if i==1, pause, end
        M(i) = getframe(hf);
    end
end

if ~isempty(fname)
    disp('converting to avi'), drawnow
    movie2avi(M,fname,'fps',fps,'compression',compression);
end

if nargout==0, clear M, end