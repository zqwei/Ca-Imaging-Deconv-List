function out = simul_noiseequalizer(nt,dt,frequencybands,spectrum,histo)
% function noise = simul_noiseequalizer(nt,dt,frequencybands,spectrum)
% function histo = simul_noiseequalizer(nt,dt,frequencybands,spectrum,'histo')
%---
% generate noise with a specific sectrum, or return the histogram of
% Fourier powers in specific frequency bands
% 
% Input:
% - nt              number of time instants
% - dt              sampling time
% - frequencybands  vector with (n+1) frequency values, where n is the
%                   number of frequency bands; ideally these values should
%                   be equally spaced in logarithm
% - spectrum        either a vector with n values, defining the power of
%                   noise in each band (in RMS^2 unit), or one of the
%                   following keywords:
%                   'whitenoise', 'pinknoise', 'classic1', 'classic2',
%                   'classic3' 
% - 'histo'         determines whether to output a noise vector, or only a
%                   histogram summary
%
% Output:
% - noise           a noise vector whose power in the different frequency
%                   bands should follow the specification; the RMS of this
%                   vector should be close to sqrt(sum(spectrum)) if
%                   spectrum is a vector, or close to 1 if spectrum is one
%                   of the keywords
% - histo           the actual power in the different frequency bands; if
%                   spectrum is a vector, histo should be approximately
%                   equal to spectrum (but not necessarily exactly equal)

% memo:
% x vector of length n
% rms(x)  = sqrt(Sum xi^2/n)
% norm(x) = sqrt(Sum xi^2)
%         = rms(x)^2 * sqrt(n)
% rms(fft(x))  = rms(x) * sqrt(n)
% norm(fft(x)) = norm(x) * sqrt(n)
% std(x,1) = rms(x-mean(x))
%          = norm(x-mean(x)) / sqrt(n)
%          = norm(fft(x-mean(x)) / n

% input
dohisto = nargin>=5 && strcmp(histo,'histo');


% size, frequencies
ntpad = 21*nt; % padding largely on both sides to avoid side effects and have fine frequency resolution
freqs = fn_fftfrequencies(ntpad,1/dt,'centered')';
freq2 = freqs.^2;

% filter to transform white noise into pink noise
adjust0 = 1./sqrt(abs(freqs));
adjust0(1) = 0;
adjust0 = adjust0/rms(adjust0); % std of the pink noise will be 1

% filter corresponding to spectrum
if ischar(spectrum)
    switch spectrum
        case 'pinknoise'
            adjust1 = adjust0;
        case 'whitenoise'
            adjust1 = ones(ntpad,1);
            adjust1(1) = 0;
            adjust1 = adjust1/rms(adjust1);
        case 'classic1'
            % 50/50 low-freq/whitenoise
            adjust1 = ones(ntpad,1);
            adjust1(1) = 0;
            adjust1 = adjust1/rms(adjust1);
            
            freqthr = 0.2;
            HWHH = sqrt(2*log(2)); % factor that translates standard deviation of a Gaussian to half-width at half-maximum
            sigma = freqthr/HWHH;
            K = 1/(2*sigma^2);
            g = exp(-K*freq2);
            adjust2 = adjust0.*g;
            adjust2 = adjust2/rms(adjust2);
            
            adjust1 = adjust1+adjust2;
            adjust1 = adjust1/rms(adjust1);
        case 'classic2'
            % 67/33 low-freq/whitenoise
            adjust1 = ones(ntpad,1);
            adjust1(1) = 0;
            adjust1 = adjust1/rms(adjust1);
            
            freqthr = 0.2;
            HWHH = sqrt(2*log(2)); % factor that translates standard deviation of a Gaussian to half-width at half-maximum
            sigma = freqthr/HWHH;
            K = 1/(2*sigma^2);
            g = exp(-K*freq2);
            adjust2 = adjust0.*g;
            adjust2 = adjust2/rms(adjust2);
            
            adjust1 = adjust1+sqrt(2)*adjust2;
            adjust1 = adjust1/rms(adjust1);
        case 'classic3'
            % 80/20 low-freq/whitenoise
            adjust1 = ones(ntpad,1);
            adjust1(1) = 0;
            adjust1 = adjust1/rms(adjust1);
            
            freqthr = 0.2;
            HWHH = sqrt(2*log(2)); % factor that translates standard deviation of a Gaussian to half-width at half-maximum
            sigma = freqthr/HWHH;
            K = 1/(2*sigma^2);
            g = exp(-K*freq2);
            adjust2 = adjust0.*g;
            adjust2 = adjust2/rms(adjust2);
            
            adjust1 = adjust1+2*adjust2;
            adjust1 = adjust1/rms(adjust1);
        otherwise
            error('unknown spectrum flag ''%s''',spectrum)
    end
else
    nband = length(frequencybands)-1;
    powerperband = spectrum*sqrt(nband); % std of a single band with power 1 will be 1
    adjust1 = 0;
    for i=1:nband
        freqthr = frequencybands([i i+1]);
        HWHH = sqrt(2*log(2)); % factor that translates standard deviation of a Gaussian to half-width at half-maximum
        sigma = freqthr/HWHH;
        K = 1./(2*sigma.^2);
        g = exp(-K(2)*freq2) - exp(-K(1)*freq2);
        adjust1 = adjust1 + adjust0.*g*powerperband(i);
    end
end

% return histogram
if dohisto
    nband = length(frequencybands)-1;
    summary = zeros(1,nband);
    nidx = zeros(1,nband);
    for i=1:nband
        freqthr = frequencybands([i i+1]);
        idx = abs(freqs)>=freqthr(1) & abs(freqs)<freqthr(2);
        summary(i) = sum(adjust1(idx).^2)/ntpad; % the RMS of fft(x) is length(x)*RMS(x)
        nidx(i) = sum(idx);
    end
    fprintf('%.2f - %.2f - %.2f\n', ...
        sum(adjust1(abs(freqs)<frequencybands(1)).^2)/ntpad, ...
        sum(summary), ...
        sum(adjust1(abs(freqs)>=frequencybands(end)).^2)/ntpad)
    
    out = summary;
    return
end

% generate noise and filter it
noise = randn(ntpad,1);
noisef = fft(noise).*adjust1;
noise = real(ifft(noisef));
noise = noise((ntpad-nt)/2+(1:nt));
out = noise;
