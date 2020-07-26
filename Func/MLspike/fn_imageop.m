function x = fn_imageop(x,par)
% function a = fn_imageop(a[,par])
% function par = fn_imageop('par')
%---
% Apply a series of transformations to an image
% 
% Input/Output:
% - a       2D (or more) array - image (or movie, ...) to be modified
% - par     structure - parameter of operations to apply; fields are:
%           .bin        binning
%           .xlow       low-pass filter
%           .xhigh      high-pass filter

% Thomas Deneux
% Copyright 2011-2017

if nargin==0, help fn_imageop, return, end

if ischar(x)
    if ~strcmp(x,'par'), error argument, end
    x = defaultpar;
else
    par1 = defaultpar;
    if nargin>=2, par1 = fn_structmerge(par1,par,'skip'); end
    x = imageop(x,par1);
end

%---
function par = defaultpar

par = struct( ...
    'xbin',     0, ...
    'xlow',     0, ...
    'xhigh',    0, ...
    'user',     []);


%---
function a = imageop(a,par)


if par.xbin>1
    if isscalar(par.xbin), par.xbin = repmat(par.xbin,1,2); end
    a = fn_bin(a,par.xbin,'same');
end

if par.xlow || par.xhigh
    idxnan = isnan(a);
    dofillnan = any(idxnan(:));
    if dofillnan, a(idxnan) = nanmean(a(:)); end
else
    dofillnan = false;
end

if par.xlow && par.xhigh
    a = fn_filt(a,[par.xlow par.xhigh],'bzm',[1 2]);
elseif par.xlow
    a = fn_filt(a,par.xlow,'lm',[1 2]);
elseif par.xhigh
    a = fn_filt(a,par.xhigh,'hzm',[1 2]);
end

if isa(par.user,'function_handle')
    a = feval(par.user,a);
elseif iscell(par.user)
    for k=1:length(par.user), a = feval(par.user{k},a); end
end

if dofillnan, a(idxnan) = NaN; end

    