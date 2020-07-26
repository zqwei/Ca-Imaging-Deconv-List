function varargout = fn_fftfrequencies(data,fs,flag)
% function ff = fn_fftfrequencies(data,fs[,'centered'])
% function [ff1 ff2] = fn_fftfrequencies(data,fs[,'centered[+shift]'])
%---
% utility to get the vector of frequencies for which fft is computed on
% data
% 
% Inputs:
% - data    vector, or scalar (then it is the number of elements of the
%           data) 
%           data can also be an array, in which case there are 2 outputs
% - fs      sampling frequency (default=1)
% - 'centered', 'center+shift'  
%           use these flag for getting the second half of the
%           frequencies being negative frequencies rather than 'above-the-
%           Niquist-limit' frequencies

% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_fftfrequencies, return, end

% Input
if nargin<2, fs=1; end
[docenter doshift]=deal(false);
if nargin>=3
    switch flag
        case 'centered'
            docenter = true;
        case 'centered+shift'
            docenter = true; 
            doshift = true;
        otherwise
            error 'unknown flag'
    end
end

% Get the data size
if isscalar(data)
    n = data;
elseif isvector(data)
    n = length(data);
else
    n = size(data);
    if isscalar(fs), fs=[fs fs]; end
end

% Get the frequencies
if length(n)==1
    if docenter
        ff = fs * [0:ceil((n-1)/2) -floor((n-1)/2):-1]/n;
        if doshift, ff = fftshift(ff); end
    else
        ff = fs * (0:(n-1))/n;        
    end
    varargout = {ff};
else
    if docenter
        ff1 = fs(1) * [0:ceil((n(1)-1)/2) -floor((n(1)-1)/2):-1]/n(1);
        ff2 = fs(2) * [0:ceil((n(2)-1)/2) -floor((n(2)-1)/2):-1]/n(2);
        if doshift, ff1 = fftshift(ff1); ff2 = fftshift(ff2); end
    else
        ff1 = fs(1) * (0:(n(1)-1))/n(1);
        ff2 = fs(2) * (0:(n(2)-1))/n(2);
    end
    if nargout<=1
        varargout = {{ff1 ff2}};
    else
        varargout = {ff1 ff2};
    end
end