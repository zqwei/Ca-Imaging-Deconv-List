function [data maskbin] = fn_bin(data,bins,varargin)
% function data = fn_bin(data,bins(vector)|xybin(scalar)[,fun][,'same'][,'mask',mask])
% function [data maskbin] = fn_bin(data,xybin(scalar)[,'mask',mask])
%---
% bin data according to vector describing which binning to apply for each 
% dimension
% for example, can be used to bin 3D data image (x,y,t) in space and time 
% 
% Input:
% - data    array of size s
% - bins    vector of length up to ndims(data); use negative values to
%           specify desired output sizes rather than bin sizes
% - fun:
%   'mean'      average over each bin [=default]
%   'sum'       sum over each bin
%   'mode'      take most frequent value inside each bin
%   'min|max'   take min or max over each bin
%   'and|or'    performs a logical 'and' or 'or' rather than averaging;
%               note that if data is a logical, 'and' is chosen by default
% - other flags:
%   'same'      make binned data same size as original
%   'sum'       sum over each block rather than averaging
%   'smart'     cover all the data; for this all blocks do not have exactly the
%               same number of elements
%   'mask',mask the first dimension in data corresponds to pixels
%               inside the provided mask: a new binned mask is computed, and
%               first dimension in the output data corresponds to pixels in
%               this new mask 
%
% See also fn_enlarge

% Thomas Deneux
% Copyright 2010-2017

if nargin==0, help fn_bin, return, end

% Input
karg=1;
op = 'mean'; op3 = false;
[dosame domask dosmart] = deal(false);
dological = islogical(data);
while karg<=length(varargin)
    flag = varargin{karg}; karg = karg+1;
    switch flag
        case 'same'
            dosame = true;
        case {'sum' 'mode'}
            op = flag;
        case {'min' 'max'}
            op = flag;
            op3 = true;
        case 'smart'
            dosmart = true;
        case 'mask'
            domask = true;
            kmask = karg;
            mask = varargin{karg}; karg = karg+1; 
        case 'and'
            dological = 1;
        case 'or'
            dological = -1;
        otherwise
            error 'unknown flag'
    end
end

% special: mask
if domask
    np = sum(mask(:));
    if ~islogical(mask) || size(data,1)~=np
        error 'mask must be of class logical, and its number of true pixels must fit the first dimension of data'
    end
    varargin{kmask:kmask+1} = [];
    maskbin = fn_bin(mask,bins,varargin{:});
    data = fn_imvect(fn_bin(fn_imvect(data,mask),bins,varargin{:}),maskbin);
    return
end

% no binning?
if prod(bins)==1
    return
end

% convert to floating numbers (if the function does not do it, Matlab will
% do it when averaging, but will convert to double where single would be
% enough)
data = fn_float(data);

% bin size
s = size(data);
nd = ndims(data);
if length(bins)==1 
    if size(data,2)==1
        bins = [bins 1];
    elseif size(data,1)==1
        bins = [1 bins];
    else % special case 'xybin'
        bins = [bins bins];
    end
elseif size(bins,2)==1
    bins = bins';
end
if length(bins)>nd
    nd = length(bins);
    s(end+1:nd) = 1;
elseif length(bins)<nd
    bins(end+1:nd) = 1;
end

% empty -> empty
if isempty(data)
    if ~dosame
        data = reshape(data,floor(s./bins));
    end
    return
end

% specification of output size rather than bin size
ispec = (bins<0);
bins(ispec) = floor( s(ispec) ./ abs(bins(ispec)) );

% prepare data (cut or extend)
bins = min(bins,s); % avoid situation where the bin size in some dimension is larger than the data
if dosame
    s2 = ceil(s./bins);
    s1 = s2.*bins;
    if any(s1~=s)
        subs = cell(1,nd);
        for dim=1:nd
            subs{dim} = 1:s(dim);
        end
        data0 = data;
        if numel(data)>1e8, disp('warning: duplicating large array'), end
        data = nan(s1);
        data = subsasgn(data,substruct('()',subs),data0);
    end
elseif dosmart
    s2 = floor(s./bins);
    bins = floor(s./s2);
else
    s2 = floor(s./bins);
    s1 = s2.*bins;
    if any(s1~=s)
        subs = cell(1,nd);
        for dim=1:nd
            subs{dim} = 1:s1(dim);
        end
        if numel(data)>1e8, disp('warning: duplicating large array'), end
        data = subsref(data,substruct('()',subs));
    end
end

% bin
if dosmart
    if ~strcmp(op,'mean')
        error '''smart'' mode does make sense only for ''mean'' operation'
    end
    if dosame
        error '''same'' and ''smart'' flag together has not been implemented yet'
    end
    % tough method because not all blocks will have exactly the same number
    % of elements
    subs0 = cell(1,nd);
    for dim=1:nd, subs0{dim} = ':'; end
    for dim=1:nd
        if bins(dim)==1, continue, end
        % some blocks will be of length bins(dim), and some bins(dim)+1
        binsides = .5 + (0:s2(dim))*s(dim)/s2(dim);
        binlefts = ceil(binsides);
        binsizes = diff(binlefts);
        bins1 = (binsizes==bins(dim));
        bins2 = (binsizes==bins(dim)+1);
        if ~all(bins1|bins2) || ~any(bins1), error programming, end
        % average over blocks of length bins(dim)
        subs = subs0;
        idx1 = false(s2(dim),1); 
        for i=find(bins1), idx1(binlefts(i):binlefts(i+1)-1) = true; end
        subs{dim} = idx1;
        data1 = subsref(data,substruct('()',subs));
        data1 = reshape(data1,[s2(1:dim-1) bins(dim) sum(bins1) s(dim+1:nd)]);
        if op3
            data1 = reshape(feval(op,data1,[],dim),[s2(1:dim-1) sum(bins1) s(dim+1:nd)]);
        else
            data1 = reshape(feval(op,data1,dim),[s2(1:dim-1) sum(bins1) s(dim+1:nd)]);
        end
        % average over blocks of length bins(dim)+1?
        if any(bins2)
            idx2 = false(s2(dim),1);
            for i=find(bins2), idx2(binlefts(i):binlefts(i+1)-1) = true; end
            subs{dim} = idx2;
            data2 = subsref(data,substruct('()',subs));
            data2 = reshape(data2,[s2(1:dim-1) bins(dim)+1 sum(bins2) s(dim+1:nd)]);
            if op3
                data2 = reshape(feval(op,data2,[],dim),[s2(1:dim-1) sum(bins2) s(dim+1:nd)]);
            else
                data2 = reshape(feval(op,data2,dim),[s2(1:dim-1) sum(bins2) s(dim+1:nd)]);
            end
            % combine both averages
            data = zeros([s2(1:dim) s(dim+1:nd)]);
            subs{dim} = bins1; data = subsasgn(data,substruct('()',subs),data1);
            subs{dim} = bins2; data = subsasgn(data,substruct('()',subs),data2);
        else
            data = data1;
        end
    end
else
    % easy method
    stemp = [bins; s2]; stemp = stemp(:)';
    data = reshape(data,stemp);
    for dim=1:nd
        if bins(dim)==1, continue, end
        if op3
            data = feval(op,data,[],2*dim-1);
        else
            data = feval(op,data,2*dim-1);
        end
    end
end

% final reshape+resize
if dosame
    repfact = [bins; ones(1,nd)]; repfact = repfact(:)';
    data = repmat(data,repfact);
    data = reshape(data,s1);
    subs = cell(1,nd);
    for dim=1:nd
        subs{dim} = 1:s(dim);
    end
    data = subsref(data,substruct('()',subs));
else
    data = reshape(data,s2);
end

% special: logical
switch dological
    case 1
        data = (data==1);
    case -1
        data = logical(data);
end
