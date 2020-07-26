function [y freqs yticklog yticklabel] = fn_spectrogram(x,dt,varargin)
% function [y freqs yticklog yticklabel] = fn_spectrogram(x,dt[,freqscaling][,freqs])
% function fn_spectrogram(['display',]y,dt|tt,freqs,yticklog,yticklabel[,freqscaling][,clip])
%---
% This is a wrapper of Matlab Wavelet Toolbox 'cwtft' function to do
% time-frequency analysis.
% The second function form is a utility to display the result.
%
% Input
% - x       ND array - signals: first dimension is time, second dimension is
%           repetition (spectrograms will be averaged along this dimension),
%           additional dimensions correspond to different conditions and will
%           not lead to averaging
%           cell array can be used as well for different conditions having
%           different numbers of repetitions each
% - dt      scalar - time bin in second
% - freqscaling     function with prototype @(f)fun(f), or a char, e.g.
%           'f', or 'sqrt(f)' - indicates how to rescale the data
%           frequency-by-frequency [default: no rescale]

% Thomas Deneux
% Copyright 2015-2017

if nargin==0, help fn_spectrogram, end

% display?
if (ischar(x) && strcmp(x,'display')) || nargin>=5
    if strcmp(x,'display')
        varargin = [dt varargin];
    else
        varargin = [x dt varargin];
    end
    displayspectrogram(varargin{:});
    return
end

% input
if nargin<2, dt = 1; end
freqscaling = []; freqs = [];
for k=1:length(varargin)
    a = varargin{k};
    if isnumeric(a)
        freqs = a;
    else
        freqscaling = a;
        if ischar(freqscaling)
            freqscaling = eval(['@(f)' freqscaling]);
        end
    end
end

% size of signals
if isvector(x), x = x(:); end
if iscell(x)
    s = size(x);
    nc = numel(x);
    for i=1:nc
        if isvector(x{i})
            x{i}=x{i}(:);
        elseif ~ismatrix(x{i})
            error argument
        end
        if i==1
            nt = size(x{i},1);
        else
            if size(x{i},1)~=nt, error argument, end
        end
    end
else
    s = size(x); s = s(3:end);
    [nt nx nc] = size(x); %#ok<ASGLU>
    x = num2cell(x,[1 2]);
end

% scales / frequencies
t = (0:nt-1)*dt;
fs = 1/dt;
if isempty(freqs)
    scales = fliplr(10.^(log10(2):.02:log10(nt/2)));
    freqs = fs./scales;
else
    scales = fs./freqs;
end
nscale = length(scales);

% compute the average spectrogram
y = zeros([nt nscale s]);
if nc>1, fn_progress('spectrogram',nc), end
for kc=1:nc
    xk = x{kc};
    nx = size(xk,2);
    if nc>1, fn_progress(kc), elseif nx>1, fn_progress('spectrogram',nx), end
    % remove baseline and pad with zeros on the sides
    npad = floor(nt/2);
    xk = [zeros([npad nx]); fn_normalize(xk,1,'-'); zeros([npad nx])];
    % compute and average
    for i=1:nx
        if nc==1 && nx>1, fn_progress(i), end
        c = cwtft(xk(:,i),'scales',scales);
        y(:,:,kc) = y(:,:,kc) + abs(c.cfs(:,npad+1:npad+nt))'/nx;
    end
end

% nice ticks
ylimlog = [floor(log10(freqs(1))) ceil(log10(freqs(end)))];
yticklog = linspace(ylimlog(1),ylimlog(2),3*diff(ylimlog)+1);
ytick = 10.^floor(yticklog) .* round(10.^mod(yticklog,1));
yticklog = log10(ytick);
yticklabel = fn_num2str(ytick,'cell');

% frequency scaling
if ~isempty(freqscaling)
    freqscales = arrayfun(freqscaling,freqs);
    y = fn_mult(y,freqscales);
end

% display 
if nargout==0
    displayspectrogram(y,t,freqs,yticklog,yticklabel)
end

%---
function displayspectrogram(y,t,freqs,yticklog,yticklabel,varargin)

% input
clip = {};
for i=1:length(varargin)
    a = varargin{i};
    if isnumeric(a)
        clip = {a};
    else
        freqscaling = a;
        if ischar(freqscaling)
            freqscaling = eval(['@(f)' freqscaling]);
        end
        freqs = freqs(:)';
        freqscales = arrayfun(freqscaling,freqs);
        y = fn_mult(y,freqscales);
    end
end

% display
[nt nfreq nc] = size(y); %#ok<ASGLU>
if isscalar(t), t = (0:nt-1)*t; end
if nc==1
    imagesc(t,log10(freqs),y',clip{:})
    xlabel 'time (s)'
    set(gca,'ydir','normal','ytick',yticklog,'yticklabel',yticklabel)
    ylabel 'frequency (Hz)'
else
    ha = fn_framedisplay(t,log10(freqs),y,'multaxes','normalaxis',clip{:});
    set(ha(1:nc),'ydir','normal','ytick',yticklog,'yticklabel','')
    set(ha(1,:),'yticklabel',yticklabel)
    xlabel(ha(1,end),'time (s)')
    ylabel(ha(1,1),'frequency (Hz)')
end

% no output
clear y


