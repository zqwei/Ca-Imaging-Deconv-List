function hl = fn_eegplot(varargin)
% function hl = fn_eegplot([t,]data[,stepflag][,flag][,line properties...])
%---
% Like Matlab function 'plot', but separates line by a distance 'ystep'
%
% Input:
% - t       vector - x-values
% - data    2D or 3D array - y-values (if 3D, the spacing is done along the
%           3rd dimension)
% - usual plot arguments
% - stepflag    the way 'ystep' is calculated:
%   . x         use ystep = x
%   . 'STD'     use ystep = mean(std(data))
%   . 'xSTD'    use ystep = x*mean(std(data)) [default is 3*STD]
%   . 'fit' 	use ystep = max(max(data)-min(data))
%   . 'xfit'    use ystep = x * max(max(data)-min(data))
% - flag    'num'   rescale the data so that y-axis values correspond to
%                   data number
%           'numtop'    same, and put the first data top instead of bottom
%
% See also fn_gridplot

% Thomas Deneux
% Copyright 2005-2017

% Input
% (data at position 1 or 2)
if nargin>1 && isnumeric(varargin{2}) && ~isscalar(varargin{2})
    [t data] = deal(varargin{1:2});
    varargin(1:2) = [];
else
    data = varargin{1};
    varargin(1) = [];
    t = 1:size(data,1);
end
data = fn_float(data);
% (other arguments)
lineopt = {}; donum = ''; ystep = [];
for i = 1:length(varargin)
    a = varargin{i};
    if isnumeric(a)
        ystep = a;
    elseif ~ischar(a)
        error argument
    elseif strcmp(a,'num')
        donum = 'bottom';
    elseif strcmp(a,'numtop')
        donum = 'top';
    elseif regexpi(a,'^([0-9\.]*)(std|fit)$');
        ystep = a;
    else
        lineopt = varargin(i:end);
        break
    end
end

% step specification
if isempty(ystep), ystep = '3STD'; end
if ischar(ystep)
    tokens = regexpi(ystep,'^([0-9\.]*)(std|fit)$','tokens');
    tokens = tokens{1};
    if isempty(tokens{1}), fact=1; else fact=str2double(tokens{1}); end
    switch lower(tokens{2})
        case 'std'
            ystep = fact*mean(mean(std(data)));
        case 'fit'
            ystep = fact*max(max(data(:))-min(data(:)));
    end
end

% dispatch data
if donum
    data = 1+(-1)^strcmp(donum,'top')*fn_normalize(data,1,'-')/ystep;
    ystep = 1;
end
if ismatrix(data), data = permute(data,[1 3 2]); end
[~, nc, nstep] = size(data);
for k=2:nstep, data(:,:,k) = data(:,:,k) + (k-1)*ystep; end

% display
hl = plot(t,data(:,:));
if ~isempty(hl)
    hl = reshape(hl,nc,nstep);
    ha = get(hl(1),'parent');
    cols = get(ha,'colororder');
    ncol = size(cols,1);
    for k=1:nstep
        set(hl(:,k),'color',cols(fn_mod(k,ncol),:),lineopt{:}) % important to have lineopt here, in case it overwrites the color
    end
    axis(ha,'tight')
    if strcmp(donum,'top'), set(ha,'yDir','reverse'), end
end
if nargout==0, clear hl, end

    
    
    
    