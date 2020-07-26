function varargout = fn_register(varargin)
% function [shift e xreg] = fn_register(x,par|ref)
% function par = fn_register('par')
%---
% Be careful with the sign: xreg is obtained as
% xreg = fn_translate(x,-shift);
% If no reference is provided, uses the average of the first 10 movie
% frames.
% x can be a color image or movie: color should then be the 4th dimension
%
% See also fn_translate, fn_xregister

% Thomas Deneux
% Copyright 2011-2017

if nargin==0, help fn_register, end

x = varargin{1};
if ischar(x)
    if ~strcmp(x,'par'), error argument, end
    varargout = {defaultpar(varargin{2:end})};
else
    par = defaultpar;
    if nargin<2
        par.ref = mean(x(:,:,1:10,:),3);
    elseif isstruct(varargin{2})
        if nargin>=2, par = fn_structmerge(par,varargin{2},'strict'); end
    else
        par.ref = varargin{2};
    end
    if size(par.ref,3)==3 && size(par.ref,4)==1
        par.ref = permute(par.ref,[1 2 4 3]);
    end
    nout = max(nargout,1);
    varargout = cell(1,nout);
    [varargout{:}] = register(x,par);
end
%if nargout==0, varargout = {}; end

end

%---
function par = defaultpar(varargin)

par.maxshift = .5;      % shift cannot exceed half of the image size [TODO!]
par.ref = 10;           % reference frame: use average of first 10 frames as default
% par.repeat = false;     % repeat the estimation with the average resampled movie as new reference frame
par.dorotation = false;
par.doscale = false;
par.doxreg = false;     % first do a global optimization
par.xlowpass = 0;       % spatial low-pass
par.xhighpass = 0;      % spatial high-pass
par.tsmoothing = 0;      % smoothing of the estimated drift!!
par.mask = [];          % use a mask
par.display = 'framenumber';    % possibilities: 'iter' (image display at each iteration), 'final' (image display of each aligned frame), 'framenumber' (frame number only), 'none'
par.maxerr = [];        % maximal error allowed: if not attained, try other initializations; [TODO!]
par.shift0 = [0 0];
par.useprev0 = true;
par.tolx = 1e-4;
par.tolfun = 1e-4;
par.FACT = 1;
par.dogradobj = false;
par.output = 'same';    % 'same' or 'valid'

% user input
for i = 1:2:length(varargin)
    f = varargin{i};
    val = varargin{i+1};
    par.(f) = val;
end

end

%---
function [shift e xreg] = register(x,par)

% Size
if any(isnan(x(:))), error 'cannot register images with NaN values', end
[ni nj nt ncol] = size(x);
if nt==3 && ncol==1 && size(par.ref,4)==3
    x = reshape(x,[ni nj 1 3]);
    nt = 1;
    ncol = 3;
end
[par.ni par.nj par.nt] = deal(ni,nj,nt);

% Reference frame
if isscalar(par.ref)
    if par.ref==0
        ref = mean(x,3);
    else
        ref = mean(x(:,:,1:min(par.ref,nt),:),3);
    end
else
    ref = double(par.ref);
    if ~isequal(size(ref),size(x(:,:,1,:)))
        error('size mismatch between data (%i-%i) and reference frame (%i-%i)',ni,nj,size(ref,1),size(ref,2))
    end
end
for i = 1:ncol
    refi = ref(:,:,i);
    ref(:,:,i) = (refi-nmean(refi(:)))/nstd(refi(:)); % normalize image
end
% filtering
tau = [par.xlowpass par.xhighpass];
if any(tau)
    if ~isempty(par.mask)
        disp 'not using the mask for spatial smoothing'
    end
    ref = fn_filt(ref,tau,[1 2]);
end
docut = any(isnan(ref(:)));
if docut
    oki = ~all(any(isnan(ref),4),2);
    okj = ~all(any(isnan(ref),4),1);
    ref = ref(oki,okj,:,:);
    if ~isempty(par.mask), par.mask = par.mask(oki,okj); end
end

% Maximal move
if isscalar(par.maxshift)
    if par.maxshift>1
        xregminoverlap = 1-par.maxshift/min([ni nj]); % approximative...
        par.maxshift = par.maxshift*[1 1];
    else
        xregminoverlap = 1-par.maxshift; % approximative...
        par.maxshift = par.maxshift*[ni nj];
    end
end
if length(par.maxshift)==2
    if par.dorotation
        par.maxshift(end+1) = pi/4;
    end
    if par.doscale
        par.maxshift(end+1) = 0.5; % in log2, i.e. scale changes by max sqrt(2)
    end
end
par.maxshift = column(par.maxshift);

% Display
if fn_ismemberstr(par.display,{'iter' 'final'})
    hf = fn_figure('fn_register');
    ha = axes('parent',hf);
    colormap(ha,gray(256))
    par.im = imagesc(permute(par.ref,[2 1 3]),'parent',ha,[-2 2]);
    axis(ha,'image')
    if nt>1, htitl = title('Registration'); end
end

% Register
opt = optimset('Algorithm','active-set','GradObj',fn_switch(par.dogradobj), ...
    'tolx',par.tolx,'tolfun',par.tolfun,'maxfunevals',1000, ...
    'display',fn_switch(par.display,'framenumber','none',par.display));
Q = column(par.FACT);
shift = zeros(2+par.dorotation+par.doscale,nt);
if nt>1 && ~strcmp(par.display,'none'), fn_progress('register frame',nt), end
if nargout>=2, e = zeros(1,nt); end

e0 = [];
    function [e de] = myfun(d)
        switch nargout
            case {0 1}
                e = energy(d.*Q,xk,ref,par)/e0;
            case 2
                [e de] = energy(d.*Q,xk,ref,par);
                e = e/e0;
                de = de/e0;
        end
    end

for k=1:nt
    if nt>1 && ~strcmp(par.display,'none')
        fn_progress(k)
        if fn_ismemberstr(par.display,{'iter' 'final'}), set(htitl,'string',sprintf('Registration %i/%i',k,nt)), end
    end
    xk = double(x(:,:,k,:));
    if docut, xk = xk(oki,okj,:,:); end
    for i = 1:ncol
        xki = xk(:,:,i);
        xk(:,:,i) = (xki-nmean(xki(:)))/nstd(xki(:)); % normalize image
    end
    % reset current shift?
    if k==1 || ~par.useprev0
        if isvector(par.shift0)
            d = par.shift0(:);
        elseif size(par.shift0,2)==nt
            d = par.shift0(:,k);
        elseif size(par.shift0,1)==nt
            d = par.shift0(k,:)';
        else
            error 'Start value is not of the appropriate size'
        end
        if (par.dorotation || par.doscale) && length(d)==2
            d(3:2+par.dorotation+par.doscale) = 0; 
        end
    end
    % filtering
    if any(tau)
        xk = fn_filt(xk,tau,[1 2]);
    end
    e0 = energy(d,xk,ref,par); % energy with the default coregistration: use it for normalization
    if e0==0
        % perfect match between reference and frame, probably because this
        % frame was chosen as reference! keep the value for d
    else
        % global registration
        if par.doxreg
            d = fn_xregister(xk,ref,xregminoverlap);
        end
        % fine sub-pixel registration
        if par.dorotation || par.doscale
            disp 'warning: registration with a rotation and/or rescale might not work properly yet!'
        end
        d = fmincon(@myfun,d./Q, ...
            [],[],[],[],-par.maxshift./Q,par.maxshift./Q,[],opt).*Q;
        if par.dorotation
            d(3) = mod(d(3)+pi,2*pi)-pi;
        end
    end
    
    %     % test whether 'energy' is a nicely continuous/differentiable function
    %     dtest = 0:.01:11; nd = length(dtest);
    %     etest = zeros(1,nd);
    %     for ktest=1:nd
    %         etest(ktest) = energy(dtest(ktest)*[1 1],xk,ref,par)/e0;
    %     end
    %     figure(9), plot(dtest,etest)
    
    % final display
    if strcmp(par.display,'final')
        par.display = 'iter';
        myfun(d);
        par.display = 'final';
    end
    
    shift(:,k) = d;
    if nargout>=2, e(k) = energy(d,xk,ref,par); end
end

% Smooth estimated drift
if par.tsmoothing
    shift = [repmat(shift(:,1),1,nt) shift repmat(shift(:,nt),1,nt)];
    shift = fn_filt(shift,par.tsmoothing,2);
    shift = shift(:,nt+1:2*nt);
end
if nargout<3, return, end

% Resample
if nt>1 && ~strcmp(par.display,'none'), fn_progress('resample frames'), end
xreg = zeros(ni,nj,nt,class(x)); %#ok<*ZEROLIKE>
for k=1:nt
    for i=1:ncol
        xreg(:,:,k,i) = fn_translate(x(:,:,k,i),-shift(:,k),'full');
    end
end

% Cut
if strcmp(par.output,'valid')
    okij = ~any(isnan(xreg),3);
    oki = okij(:,round(nj/2));
    okj = okij(round(ni/2),:);
    xreg = xreg(oki,okj,:,:);
end

end

%---
function [e de] = energy(d,x,ref,par)

DODEBUG = false;
if DODEBUG, fprintf('%f ',d), fprintf('\n'), end

doJ = (nargout==2);

if size(x,4)==3
    % color image
    if doJ, error 'not implemented yet', end
    e = zeros(1,3);
    for i=1:3
        e(i) = energy(d,x(:,:,i),ref(:,:,i),par);
    end
    e = sum(e);
    return
end

if par.dorotation || par.doscale
    if doJ, error 'gradient not implemented for rotation or rescaling', end
    [ni nj] = size(ref);
    center = [(1+ni)/2; (1+nj)/2];
    if par.dorotation, theta = -d(3); else theta = 0; end % inverse rotation
    if par.doscale, scale = 2^d(3+par.dorotation); else scale = 1; end
    M = scale*[cos(theta) -sin(theta); sin(theta) cos(theta)];
    [ii jj] = ndgrid(1:ni,1:nj);
    p = fn_add( ...
        M*[row(ii); row(jj)], ...   % inverse rotation with center (0,0)
        center-M*center ...         % translation to have a rotation with center the center of the image
        -column(d(1:2)) ...         % inverse translation
        );
    if isempty(par.mask)
        xpred = interpn(ref,p(1,:),p(2,:),'spline',NaN);
        xpred = reshape(xpred,ni,nj);
        mask = ~isnan(xpred);
        xpred = xpred(mask);
    else
        xpred = interpn(ref,p(1,par.mask),p(2,par.mask),'spline',NaN)';
        maskinmask = ~isnan(xpred);
        mask = par.mask; mask(par.mask) = maskinmask;
        xpred = xpred(maskinmask);
    end
    weight = mask / sum(mask(:));
else
    [xpred weight] = fn_translate(ref,d,'valid');
end
% end
mask = logical(weight);

if strcmp(par.display,'iter')
    showimages(x,xpred,mask,par)
end

if isempty(par.mask)
    xpred = xpred(:);
else
    xpred = xpred(par.mask(mask));
    mask = mask & par.mask;
end
N = length(xpred);
dif = xpred - x(mask);
dif = dif - mean(dif); % subtract the mean for not being influenced by global luminance changes - this is not taken into account in the calculation of the derivative!
dif2 = dif.^2;
weight = weight(mask);
% weight = weight/sum(weight(:));

e  = sum(dif2.*weight);
if DODEBUG, fprintf('\b -> e = %f\n',e), end
if doJ
    %     % TODO: still, something is not good with the derivative, in particular at integer values of shift
    %     J = reshape(J,[N 2]);
    %     dweight = reshape(dweight,[par.ni*par.nj 2]);
    %     dweight = dweight(mask,:);
    %
    %     de = 2*(dif.*weight)'*J + sum(repmat(dif2,1,2).*dweight);
    
    % compute derivative by hand, but with some smart choices
    de = zeros(1,length(d));
    for dim=1:length(d)
        switch dim
            case {1 2}
                dd = .1; % tenth of a pixel
            case 3
                dd = asin(.1/(max(ni,nj)/2)); % rotation that results in a motion of a tenth of a pixel in the most distant point from the center
        end
        d1 = d; d1(dim) = d(dim)+dd;
        e1 = energy(d1,x,ref,par);
        if e1<e
            de(dim) = (e1-e)/dd;
        else
            d2 = d; d2(dim) = d(dim)-dd; % test also the other direction!!
            e2 = energy(d2,x,ref,par);
            de(dim) = (e1-e2)/(2*dd);
            if e2>=e
                if DODEBUG, fprintf('local minimum in dimension %i, attenuating by 10000\n',dim), end
                de(dim) = de(dim)/10000;
            end
        end
    end
    % exagerating the derivative
    de = de*100;
    if DODEBUG, fprintf('-> de = '), fprintf('%f ',de), fprintf('\n'), end
end

end

%---
function showimages(x,xpred,mask,par)

a = x;
a(mask) = a(mask)-xpred(:);
if ~isempty(par.mask), a(~par.mask) = 0; end
set(par.im,'cdata',a')
drawnow

end


