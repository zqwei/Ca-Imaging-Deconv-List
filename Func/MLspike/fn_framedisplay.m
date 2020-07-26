function out = fn_framedisplay(varargin)
% [im/ha =] function fn_framedisplay([x,[y,...]]data[,clip][,'singleaxes|multaxes'] ...
%       [['ncol',]ncol][,'in',hf|ha][,'display'][,'normalaxis'][,'nocolor'])
%---
% Input (except for data, order of inputs can be changed):
% - x,y     x and y range
% - data    3D or 4D data; NOT using Matlab image convention (i.e. first
%           dim is x and second dim is y)
%           if the third dimension is of length 3, it is assumed to
%           represent color; to avoid this assumption to take place, place
%           the additional flag 'nocolor' in the argument list
% - clip    clipping range or 'fit'
% - axflag  'singleaxes' will create a large image by putting each frame
%           next to each other and display this image
%           'multaxes' will display each frame in a separate axes
%           If axflag is not specified, 'multaxes' will be used iff the
%           number of frames is small.
% - ncol    specify the number of columns to use; the 'ncol' flag is not
%           necessary
% - hf|ha   handle of figure or axes (implicit'singleaxes' option)
%           for figure handle, it is necessary to precede it by the 'in'
%           flag (otherwise the argument is ambiguous with ncol), for axes
%           handle, this is not necessary
% - 'display'    by default, nothing is displayed if an output is requested,
%           this option is used to display even if there is an output
% - 'normalaxis' do not set the axes aspect ratio
% - 'nocolor'    explicitely tell the function not to try to detect a color
%           channel
%
% Output:
% - im      a large image obtained by concatenating all images, note that
%           compared to the large image created with the 'singleaxes'
%           option, this image is slighlty larger since there is a 1-pixel
%           wide separation between all frames
% - ha      if axflax is 'multaxes', the output is the set of axes handles

% Thomas Deneux
% Copyright 2011-2017

if nargin==0, help fn_framedisplay, return, end
% Input
% (scan varargin)
data = []; rangearg = {}; 
clip = []; axesflag = ''; in = []; 
dooutput = (nargout==1); dodisplay = ~dooutput;
ncol = []; nrow = []; doaxisratio = true;
nocolor = false;
founddata = 0; % 0: not found yet; 1: found; -1: not found, reached options
karg = 0;
while karg<length(varargin)
    karg = karg+1;
    a = varargin{karg};
    if ischar(a)
        if ~founddata, founddata = -1; end
        switch a
            case 'display'
                dodisplay = true;
            case {'singleaxes' 'multaxes'}
                axesflag = a;
            case {'axisnormal' 'normalaxis'}
                doaxisratio = false;
            case {'in' 'parent'}
                in = varargin{karg+1};
                karg = karg+1;
            case 'ncol'
                ncol = varargin{karg+1};
                karg = karg+1;
            case 'nrow'
                nrow = varargin{karg+1};
                karg = karg+1;
            case 'clip'
                clip = varargin{karg+1};
                karg = karg+1;
            case {'fit' 'fitz'}
                clip = a;
            case {'nocol' 'nocolor'}
                nocolor = true;
            otherwise
                error('unknown flag: ''%s''',a)
        end
    else
        % numerical or cell array
        if founddata~=0
            % numerical options are allowed only after the data
            if isnumeric(a) && isscalar(a) && ~mod(a,1) && isempty(ncol)
                ncol = a;
            elseif all(ishandle(a(:))) && (isscalar(a) || strcmp(get(a(1),'type'),'axes'))
                in = a;
            elseif isnumeric(a) && numel(a)==2
                clip = a;
            else
                error argument
            end
        elseif (iscell(a) && isnumeric(a{1})) || (~isempty(a) && ~isvector(a))
            % this is the data
            data = a;
            founddata = true;
        else
            rangearg{end+1} = a; %#ok<AGROW>
        end
    end
end
% (data)
if founddata<=0
    if ~ismember(length(rangearg),[1 3])
        error 'input to fn_framedisplay.m is ambiguous, use ''clip'', ''in'', ''ncol'' flagws'
    end
    data = rangearg{end};
    rangearg(end) = [];
end
if iscell(data), data = cat(4,data{:}); end
% (sizes)
s = size(data); s(end+1:5) = 1;
nx = s(1); ny = s(2);
if isreal(data) && (s(3)~=3 || s(4)==1 || nocolor)
    % standard movie
    nc = 1;
    nt = [s(3) prod(s(4:end))];
elseif ~isreal(data)
    % complex numbers: real and imaginary part make 2 separate channels
    data = cat(3,real(data),imag(data));
    nc = 1;
    nt = [2 prod(s(3:end))];
elseif s(3)==3
    % color movie
    nc = 3;
    nt = [s(4) prod(s(5:end))];
else
    error('number of dimensions of data must be 3 or 4')
end
data = reshape(data,[nx ny nc nt]);
% (axes flag)
if isempty(axesflag)
    if dooutput
        axesflag = 'output';
    elseif ~isempty(in) && ~isscalar(in)
        axesflag = 'multaxes';
    elseif ~isempty(in) && strcmp(get(in,'type'),'axes')
        axesflag = 'singleaxes';
    elseif length(rangearg)>2 || ...
            (length(rangearg)==2 && length(rangearg{1})==nx && length(rangearg{2})==ny)
        axesflag = 'multaxes';
    else
        axesflag = fn_switch(prod(nt)>6,'singleaxes','multaxes');
    end
end
% (x,y)
if strcmp(axesflag,'multaxes')
    if isempty(rangearg)
        x = 1:nx;
        y = 1:ny;
    else
        if isempty(rangearg{1})
            x = 1:nx;
        elseif length(rangearg{1})==nx
            x = rangearg{1};
        else
            error 'x length does not fit the size of the data'
        end
        if isempty(rangearg{2})
            y = 1:ny;
        elseif length(rangearg{2})==ny
            y = rangearg{2};
        else
            error 'y length does not fit the size of the data'
        end
        rangearg(1:2) = [];
    end
end
% (tt or t1,t2)
[tt t1 t2] = deal([]);
if any(nt==1)
    if isempty(rangearg)
        if ismember(axesflag,{'singleaxes' 'output'})
            tt = 1:prod(nt); 
        end
    elseif length(rangearg{1})==prod(nt)
        tt = rangearg{1};
    else
        error 'range length does not fit the size of data'
    end
else
    if isempty(rangearg)
        if ismember(axesflag,{'singleaxes' 'output'})
            t1 = 1:nt(1);
            t2 = 1:nt(2);
        end
    elseif length(rangearg{1})==nt(1) && length(rangearg{2})==nt(2)
        t1 = rangearg{1}; 
        t2 = rangearg{2};
    else
        error 'range lengths do not fit the size of data'
    end
end
% (clipping)
if nc==1
    if isempty(clip), clip = '2SD'; end
    clip = fn_clip(data,clip,'getrange');
    if any(isnan(clip)), clip = [-1 1]; elseif ~diff(clip), clip = clip+[-.5 .5]; end
end

% create axes
switch axesflag
    case {'singleaxes' 'output'}
        if dodisplay
            ha = in;
            if isempty(ha), ha = gca; end
            if ~strcmp(get(ha,'type'),'axes'), error('wrong axes handle'), end
        end
    case 'multaxes'
        dodisplay = true;
        if isempty(in) || (isscalar(in) && fn_ismemberstr(get(in,'type'),{'figure' 'uipanel'}))
            if isempty(in), hf = gcf; else hf = in; end
            switch get(hf,'type')
                case 'figure'
                    clf(hf)   
                    axes('pos',[-1 -1 .1 .1],'parent',hf) % prevent bug in ps2pdf
                case 'uipanel'
                    delete(setdiff(findall(hf),hf))
            end
            hatest = axes('parent',hf,'visible','off');
            axpos = fn_pixelpos(hatest);
            delete(hatest)
            ha = []; % will be defined later
        else
            %if doaxisratio, error 'axis ratio cannot be set when axes handles are supplied by user', end
            hf = get(in(1),'parent');
            ha = in;
        end
end

% get axes size ratio
if dodisplay
    if strcmp(axesflag,'multaxes')
        siz = fn_pixelsize(hf);
    else
        siz = fn_pixelsize(ha(1));
    end
    haratio = siz(2)/siz(1);
else
    haratio = 1;
end
    
% image ratio
xratio = ny/nx;

% number of rows and columns
rowcolratio = haratio/xratio;
permuterowcol = false;
if strcmp(axesflag,'multaxes') && ~isempty(ha)
    % axes handles are supplied by user, nothing to do
    nfr = prod(nt);
    if numel(ha)~=nfr, error 'number of supplied axes does not match number of images', end
    [ncol nrow] = size(ha);
elseif any(nt==1)
    % only one condition: number of rows and columns can be arbitrary
    nt = prod(nt);
    if ~isempty(nrow)
        if isempty(ncol)
            ncol = ceil(nt/nrow);
        end
    else
        if isempty(ncol)
            ncol = round(sqrt(nt/rowcolratio));
            ncol = max(ncol,1);
        end
        nrow = ceil(nt/ncol);
    end
    nfr = nt;
    % update frame ticks
    if isnumeric(tt) && isvector(tt) && ~any(diff(tt,2))
        if isscalar(tt), dt = 0; else dt = diff(tt(1:2)); end
        t1 = (1:ncol)*dt;
        t2left = (tt(1)-.5*dt)+(0:nrow-1)*(dt*ncol); % times at the left of each row
        t2center = t2left + .5*(dt*ncol); % times at the center of each row
        t2 = t2center;
    elseif ~isempty(tt) % non-numeric, or non equally spaced
        t1 = [];
        t2 = tt(1:ncol:end);
    end
else
    % several conditions: choose the best organization between rows and
    % coluns
    if isempty(ncol)
        testratio = nt(2)/nt(1);
        if abs(log(rowcolratio*testratio)) < abs(log(rowcolratio/testratio))
            % use nt(1) rows and nt(2) columns rather than the opposite
            permuterowcol = true;
            nt = nt([2 1]);
            data = permute(data,[1 2 3 5 4]); [t1 t2] = deal(t2,t1);
        end
    elseif ncol~=nt(1)
        if ncol==nt(2)
            nt = nt([2 1]);
            data = permute(data,[1 2 3 5 4]); [t1 t2] = deal(t2,t1);
        else
            error('number of columns does not match any dimension of data')
        end
    end
    ncol = nt(1);
    nrow = nt(2);
    nfr = prod(nt);
    data = reshape(data,[nx ny nc nfr]);
end

% one or several axes?
if fn_ismemberstr(axesflag,{'singleaxes' 'output'})
    % make new image and fill it with frames
    if islogical(data)
        defval = false;
    else
        m = min(data(:)); M = max(data(:));
        if isempty(data) || any(isnan(data(:)))
            defval = NaN;
        elseif m<=0 && M>=0
            defval = 0;
        elseif m<=1 && M>=1
            defval = 1;
        else
            defval = NaN;
        end
    end
    if nfr<ncol*nrow, data(:,:,:,end+1:ncol*nrow) = defval; end
    data = reshape(data,nx,ny,nc,ncol,nrow);
    data = permute(data,[2 5 1 4 3]);
    if dooutput
        % add a separation between frames
        data(ny+1,:) = 0;
        data(:,:,nx+1,:) = 0;
        data = reshape(data,(ny+1)*nrow,(nx+1)*ncol,nc);
        data = [zeros([1 1+(nx+1)*ncol nc]); zeros([(ny+1)*nrow 1 nc]) data]; 
    else
        data = reshape(data,ny*nrow,nx*ncol,nc);
    end
    
    % display and add lines to separate frames
    if dodisplay && isempty(data)
        cla(ha)
    elseif dodisplay
        if isempty(t1) || isscalar(t1) || ~isnumeric(t1) || any(diff(diff(t1))), xscale = [1 1]; else xscale = [t1(1) diff(t1(1:2))]; end
        if isempty(t2) || isscalar(t2) || ~isnumeric(t2) || any(diff(diff(t2))), yscale = [1 1]; else yscale = [t2(1) diff(t2(1:2))]; end
        xlim = xscale(1) + xscale(2)*([0 ncol-1] + [-1 1]*(nx-1)/(2*nx));
        ylim = yscale(1) + yscale(2)*([0 nrow-1] + [-1 1]*(ny-1)/(2*ny));
        if nc==3
            imagesc(xlim,ylim,data,'parent',ha)
        else
            imagesc(xlim,ylim,data,'parent',ha,clip)
        end
        if doaxisratio, set(ha,'DataAspectRatio',[ny/yscale(2) nx/xscale(2) 1]), end
        if ~dooutput
            for i=0:ncol
                line(xscale(1)+xscale(2)*[1 1]*(i-.5),yscale(1)+yscale(2)*[-.5 nrow-.5], ...
                    'parent',ha,'color','k')
            end
            for j=0:nrow
                line(xscale(1)+xscale(2)*[-.5 ncol-.5],yscale(1)+yscale(2)*[1 1]*(j-.5), ...
                    'parent',ha,'color','k')
            end
        end
        if ~isempty(t1) && (~isnumeric(t1) || any(diff(diff(t1))))
            if isnumeric(t1), t1 = fn_num2str(t1,'cell'); end
            set(ha,'xtick',1:ncol,'xticklabel',t1)
        end
        if ~isempty(t2) && (~isnumeric(t2) || any(diff(diff(t2))))
            if isnumeric(t2), t2 = fn_num2str(t2,'cell'); end
            set(ha,'ytick',1:nrow,'yticklabel',t2)
        end
    end
    
    % output?
    if dooutput
        out = permute(data,[2 1 3]);
    end
else
    % change positions of 'containing' axes to make square images
    if ~isempty(ha)
        % axes supplied by user, nothing to do
    else
        left = axpos(1); bottom = axpos(2); w = axpos(3); h = axpos(4);
        if doaxisratio
            mxratio = (ny*nrow)/(nx*ncol);
            r = haratio/mxratio;
            if r>1
                bottom = bottom + (h-h/r)/2;
                h = h/r;
            else
                left = left + (w-w*r)/2;
                w = w*r;
            end
        end
        w = w/ncol; h = h/nrow;
        % go! make multiple axes and display frames inside them
        defunits = get(hf,'defaultaxesunits');
        ha = zeros(1,nfr);
    end
    % frame ranges
    if ~iscell(t1), t1 = fn_num2str(t1,'cell'); end
    if ~iscell(t2), t2 = fn_num2str(t2,'cell'); end
    % display loop
    k = 0;
    for j=1:nrow
        for i=1:ncol
            k = k+1;
            if k>nfr, break, end
            if ha(k)==0
                ha(k) = axes('parent',hf, ...
                    'units','pixel','pos',[left+(i-1)*w bottom+(nrow-j)*h w h], ...
                    'units',defunits); 
            end
            switch nc
                case 1
                    imagesc(x,y,data(:,:,:,k)','parent',ha(k),clip);
                case 3
                    imagesc(x,y,permute(data(:,:,:,k),[2 1 3]),'parent',ha(k));
            end
            if doaxisratio, axis(ha(k),'image'), end
            if j<nrow
                set(ha(k),'xticklabel','')
            elseif ~isempty(t1)
                xlabel(t1{i})
            end
            if i>1
                set(ha(k),'yticklabel','')
            elseif ~isempty(t2)
                ylabel(ha(k),t2{j},'rotation',0,'horizontalalignment','right')
            end
        end
    end
    %fn_clipcontrol(ha);
    
    % output?
    if dooutput
        out = zeros(ncol,nrow);
        if permuterowcol
            out = out'; out(1:nfr) = ha; out = out';
        else
            out(1:nfr) = ha;
        end
    end
end



