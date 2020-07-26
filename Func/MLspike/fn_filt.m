function y = fn_filt(x,tau,varargin)
% function y = fn_filt(x,tau[,'l|h|b|n'][,dim][,filtertype][,'mirror']['mask'[,mask]][,'zero'][,'detrend']['complex|phase'])
% function y = fn_filt(x,tau[,options][,dim])
% function y = fn_filt(x,'detrend|detrendz'[,dim])
%---
% FFT-based filter
%
% Input:
% - x       ND array - data
% - tau     scalar or 2-elements vector or 2-element cell array - threshold
%           period expressed in number of samples (tau = fsampling/fthresh)
%           A sine wave of frequency fthresh will have its amplitude
%           divided by two after filtering. Low-pass filtering with fn_filt
%           is equivalent to convolution with a Gaussian kernel of standard
%           deviation sqrt(2*log(2))/(2*pi)*tau...
%           If there are 2 elements, they must verify tau(1) < tau(2)
% - type    'l' for low-pass, 'h' for high-pass, 'b' for band-pass, 'n' for
%           notch
%           if type is not specified, it is gueesed from the format of the
%           'tau' argument: 
%           taul or [taul 0] will result in a low-pass filtering
%           [0 tauh] will result in a high-pass filtering
%           [taul tauh] will result in a band-pass filtering
% - dim     1, 2, or [1 2] - dimension where to apply the filter ([1 2]
%           results in a 2-dimensional filtering)
% - filtertype    
%           'gaussian'  [default] performs a Gaussian fft filter
%           'sharp'     performs a 0-1 fft filter (warning: this creates
%                       oscillations at near-threshold frequencies)
%           'butterN'   Butterworth filter of order N (if N is omitted,
%                       default value of N=2 is used)
% - 'mirror'      
%           data will be padded with its mirror reflections before
%           filtering, instead of the default which effectively does wrap
%           around 
% - 'mask|maskin'
%           points that do not have a full neighborhood are adjusted
%           use 'maskin' flag to mask the input that is outside the mask, 
%           but not the output (e.g. for a low pass filter, the holes will
%           be filled-in)
% - 'zero'  will preserve the constant even in the case of high-pass and
%           band-pass
% - 'detrend'           
%           removes (if high-pass or band-pass) or keep! (if
%           low-pass or notch) a linear trend; use fn_filt(x,'detrend')  
%           to perform only a detrending!, and fn_filt(x,'detrendz') to
%           remove only the trend but not the constant
% - 'complex'
%           return a complex signal
% - 'phase' or 'phase01'
%           return the phase of the complex signal; 'phase01' results in
%           values between 0 and 1 instead of between -pi and pi
% - options a string summarizing all options: for example 'hmz' results in
%           a high-pass filter, using mirror padding, and preserving the
%           constant
%           available shortcuts are:
%           l,h,b,n     type (Low,High,Band,Notch)
%           g,s,u       filter type (Gaussian,Sharp,bUtter)
%           z           zero
%           d           detrend
%           m           mirror
%           k           mask
%           
%
% Output:
% - y       filtered data

% Thomas Deneux
% Copyright 2015-2017

if nargin==0, help fn_filt, return, end

% Input
% (analyze arguments)
type = []; filtertype = 'gaussian';
domirror = false; domask = false; domaskout = false;
dozero = false; dodetrend = false; 
docomplex = false; 
dim = 1;
if ischar(tau)
    if ~fn_ismemberstr(tau,{'detrend','detrendz'}) error 'argument', end
    dodetrend = true;
    filtertype = 'detrend';
    dozero = strcmp(tau,'detrendz');
    tau = [0 0];
end
k=0;
while k<length(varargin)
    k= k+1;
    a = varargin{k};
    if ischar(a)
        switch a
            case 'mirror'
                domirror = true;
            case {'mask' 'maskin'}
                domask = true;
                domaskout = ~strcmp(a,'maskin');
                if length(varargin)>k && ~ischar(varargin{k+1})
                    mask = varargin{k+1};
                    k = k+1;
                else
                    mask = [];
                end
            case {'gaussian' 'sharp'}
                filtertype = a;
            case 'zero'
                dozero = true;
            case 'detrend'
                dodetrend = true;
            case 'complex'
                docomplex = true;
                phaseflag = '';
            case 'phase'
                docomplex = true;
                phaseflag = a;
            otherwise
                if strfind(a,'butter')
                    filtertype = 'butter';
                    tokens = regexp(a,'^butter(\d)*$','tokens');
                    if isempty(tokens), error argument, end
                    N = num2str(tokens{1}{1});
                    if isempty(N), N=2; end
                else
                    for i=1:length(a)
                        switch a(i)
                            case {'l' 'h' 'b' 'n'}
                                type = a(i);
                            case 'm'
                                domirror = true;
                            case 'g'
                                filtertype = 'gaussian';
                            case 's'
                                filtertype = 'sharp';
                            case 'u'
                                filtertype = 'butter';
                                N = 2;
                            case 'z'
                                dozero = true;
                            case 'd'
                                dodetrend = true;
                            case 'k'
                                domask = true;
                                mask = [];
                            otherwise
                                error 'unknown option'
                        end
                    end
                end
        end
    else
        dim = a;
    end
end
% (tau: time constants)
if iscell(tau)
    for k=1:2, if isempty(tau{k}), tau{k}=0; end, end
    tau = [tau{:}];
end
if all(tau==0)
    if dodetrend
        filtertype = 'detrend';
    else
        % nothing to do
        y = x;
        return
    end
elseif isscalar(tau) 
    if isempty(type)
        type = 'l'; 
        tau = [tau 0];
    elseif type=='l'
        tau = [tau 0];
    elseif type=='h';
        tau = [0 tau];
    else
        error 'two time (or space) constants must be supplied for a band-pass or notch filter'
    end
elseif ~isvector(tau) || length(tau)~=2
    error 'tau must be a scalar or a 2-element vector'
elseif isempty(type) || (type=='b' && any(tau==0))
    type = fn_switch(tau(1)==0,'h',tau(2)==0,'l','b');
elseif (type=='l' && tau(2)~=0) || (type=='h' && tau(1)~=0)
    error 'incorrect frequency specification'
end
if diff(tau)<0 && ismember(type,'bn')
    % time or space constants in decreasing order lead to trivial
    % filtering!
    if type=='n'
        y = x; % width of notch is inexistent!
    elseif ~dozero
        y = zeros(size(x)); % all frequencies have been filtered out!
    else
        m = x;
        for k=1:length(dim)
            m = mean(m,dim(k));
        end
        tmp = ones(1,ndims(x));
        for k=1:length(dim), tmp(dim(k)) = size(x,dim(k)); end
        y = repmat(m,tmp);
    end
    return
end
% (check dim)
if ~isscalar(dim) && ~isequal(dim,[1 2])
    error 'dim must be a scalar or [1 2]'
end
% (check complex flags)
if docomplex && ~ismember(filtertype,{'gaussian' 'sharp'})
    error 'only fft filter can return complex values'
end
if domask && dodetrend
    error('''mask'' and ''detrend'' options are not compatible')
end
if domask && domirror
    error('''mask'' and ''mirror'' options are not compatible')
end
if domask && docomplex
    error('''mask'' and ''complex'' options not implemented together yet')
end

% Size and type
s = size(x);
xtype = class(x);

% Remove NaNs
badidx = isnan(x);
x(badidx) = mean(x(~badidx));

% Detrend
if dodetrend
    if ~isscalar(dim), error 'detrend is not possible for 2D filtering', end
    regr  = (0:s(dim)-1)'/s(dim); regr = regr-mean(regr); % linear regressor
    regr1 = (regr'*regr)^-1*regr'; % pseudo-inverse: estimation of the linear component
    regr  = shiftdim(regr,-(dim-1));  % bring column vector to the good dimension
    regr1 = shiftdim(regr1,-(dim-2)); % bring row vector to the good dimension
    beta  = sum(fn_mult(x,regr1),dim);
    trend = fn_mult(beta,regr);
    x = x-trend;
    if strcmp(filtertype,'detrend')
        % detrend only, no additional filtering
        if ~dozero, x = fn_normalize(x,dim,'-'); end
        y = x;
        return % No need to continue with Fourier!
    end
end

% Mask
if domask
    if isempty(mask)
        smask = ones(1,length(s));
        for i=dim, smask(i) = s(i); end
        mask = ones(smask);
        dopad = true;
    else
        mask = double(mask);
        dopad = false;
        maxtau = max(tau); % pad with twice the period
        subs0 = repmat({':'},1,length(dim));
        if isscalar(dim), mask = column(mask); end
        for k=1:length(dim)
            nk = s(dim(k));
            npad(k) = ceil(min(nk,2*maxtau)); %#ok<AGROW>
            subs = subs0;
            subs{k} = [1:npad(k) nk-npad(k)+1:nk];
            bands = fn_subsref(mask,subs{:});
            if any(bands(:))
                dopad = true;
                break
            end
        end
    end
    switch type
        case 'l'
            % everything is fine: we will normalize the low-passed signal
            % by the low-passed mask
            highpassmask = false;
        case 'h'
            % normalization can be only by a low-passed mask: we will first
            % low-pass (with mask) the signal, and then take the difference
            type = 'l';
            tau = [tau(2) 0];
            highpassmask = true;
        otherwise
            error '''mask'' option is possible only for low-pass and high-pass'
    end
    x = fn_mult(x,mask);
else
    dopad = false;
end

% Padding / Mirroring
if domirror || dopad
    maxtau = max(tau); % pad with twice the period
    subs0 = repmat({':'},1,ndims(x));
    for k=1:length(dim)
        nk = s(dim(k));
        npad(k) = ceil(min(nk,2*maxtau)); %#ok<AGROW>
        if domirror
            subs = subs0;
            subs{dim(k)} = [npad(k):-1:1 1:nk nk:-1:nk-npad(k)+1];
            x = fn_subsref(x,subs{:});
        elseif domask
            s1 = size(x); s1(dim(k)) = npad(k);
            x = cat(dim(k),zeros(s1),x,zeros(s1));
            s1 = size(mask); s1(dim(k)) = npad(k);
            mask = cat(dim(k),zeros(s1),mask,zeros(s1));
        else
            error programming
        end
    end
end
s1 = size(x);

% Filter
switch filtertype
    case {'gaussian' 'sharp'}
        % fft filtering
        dogaussian = strcmp(filtertype,'gaussian');
        
        % Get data in Fourier space
        x = double(x); % must work with double-precision numbers
        if isscalar(dim)
            xf = fft(x,[],dim);
            if domask, maskf = fft(mask,[],dim); end
        else
            xf = zeros(s1);
            for k=1:prod(s1(3:end))
                xf(:,:,k) = fft2(x(:,:,k));
            end
            if domask, maskf = fft2(mask); end
        end
        
        % Filter definition in Fourier space
        if isscalar(dim)
            nk = s1(dim);
            freqs = [0:ceil((nk-1)/2) -floor((nk-1)/2):-1]' / nk; % frequencies in cycles/frame
            freqs = shiftdim(freqs,1-dim);
            freq2 = freqs.^2;
        else
            if ~isequal(dim,[1 2]), error programming, end
            freqi = [0:ceil((s1(1)-1)/2) -floor((s1(1)-1)/2):-1]' / s1(1); % cycles / pixel
            freqj = [0:ceil((s1(2)-1)/2) -floor((s1(2)-1)/2):-1]' / s1(2);
            [freqi freqj] = ndgrid(freqi,freqj);
            freq2 = freqi.^2 + freqj.^2;
        end
        HWHH = sqrt(2*log(2)); % factor that translates standard deviation of a Gaussian to half-width at half-maximum
        freqthr = (1./tau);
        if dogaussian
            sigma = freqthr/HWHH;
            K = 1./(2*sigma.^2);
            K(isinf(K)) = 1e6; % handle Inf
            switch type
                case 'l'
                    g = exp(-K(1)*freq2);
                case 'h'
                    g = 1 - exp(-K(2)*freq2);
                case 'b'
                    g = exp(-K(1)*freq2) - exp(-K(2)*freq2);
                case 'n'
                    g = 1 - exp(-K(1)*freq2) + exp(-K(2)*freq2);
            end
        else
            switch type
                case 'l'
                    g = (freq2 <= freqthr(1)^2);
                case 'h'
                    g = (freq2 > freqthr(2)^2);
                case 'b'
                    g = (freq2 <= freqthr(1)^2) & (freq2 > freqthr(2)^2);
                case 'n'
                    g = (freq2 > freqthr(1)^2) | (freq2 <= freqthr(2)^2);
            end
        end
        if dozero
            g(1) = 1;
        end
        if docomplex
            if isscalar(dim)
                g(2:ceil(nk/2)) = g(2:ceil(nk/2))*2;
                g(1+floor(nk/2)+1:end) = 0;
            else
                error 'complex filtering not implemented yet for 2D'
            end
            if ~isempty(phaseflag)
                % it does not make any sens to keep a constant for phase
                % calculation, ignore the 'zero' flag and remove the
                % constant
                g(1) = 0;
            end
        end
        
        % Apply filter in Fourier space
        xf = fn_mult(xf,g);
        if domask, maskf = fn_mult(maskf,g); end
        
        % Inverse Fourier
        if isscalar(dim)
            y = ifft(xf,[],dim);
            if ~docomplex
                y = real(y);
            elseif ~isempty(phaseflag)
                y = angle(y);
                if strcmp(phaseflag,'phase01'), y = (y/pi+1)/2; end
            end
            if domask, maskf = real(ifft(maskf,[],dim)); end
        else
            y = zeros(s1);
            for k=1:prod(s1(3:end))
                yk = ifft2(xf(:,:,k));
                if docomplex
                    if ~isempty(phaseflag)
                        yk = angle(yk);
                        if strcmp(phaseflag,'phase01'), yk = (yk/pi+1)/2; end
                    end
                    y(:,:,k) = yk;
                else
                    y(:,:,k) = real(yk);
                end
            end
            if domask, maskf = real(ifft2(maskf)); end
        end
        
    case 'butter'
        % Butterworth filter
        if domask, error 'not implemented yet', end
        freqthr = 1./tau; % frequency cut-off
        Wn = freqthr*2; % 1 <-> Nyquist
        switch type
            case 'l'
                if ischar(N), N = str2double(N); end
                [b a] = butter(N,Wn(1),'low');
                y = filter(b,a,x,[],dim);
            case 'h'
                [b a] = butter(N,Wn(2),'low');
                y = filter(b,a,x,[],dim);
                if dozero, y = fn_add(y,mean(x,dim)); end
            case 'b'
                [b1 a1] = butter(N,Wn(1),'low');
                [b2 a2] = butter(N,Wn(2),'low');
                y = filter(b1,a1,x,[],dim) - filter(b2,a2,x,[],dim);
                if dozero, y = fn_add(y,mean(x,dim)); end
            case 'n'
                [b1 a1] = butter(N,Wn(1),'high');
                [b2 a2] = butter(N,Wn(2),'low');
                y = filter(b1,a1,x,[],dim) + filter(b2,a2,x,[],dim);
        end
end

% Use mask to correct point on sides
if domask
    y = fn_div(y,maskf);
    if highpassmask, y = x-y; end
    if domaskout, y = fn_mult(y,mask); end % masked part has to be zero
end
    
% Un-pad if mirroring was on
if domirror || dopad
    subs0 = repmat({':'},1,ndims(x));
    for k=1:length(dim)
        nk = s(dim(k));
        subs = subs0; 
        subs{dim(k)} = npad(k)+(1:nk);
        y = fn_subsref(y,subs{:});
    end
end

% Un-detrend if low pass or notch!
if dodetrend && any(type=='ln')
    y = y+trend;
end

% Put back NaNs!
y(badidx) = NaN;

% Back to single precision?
if ~strcmp(xtype,'double') %#ok<STISA>
    y=single(y);
end
    
