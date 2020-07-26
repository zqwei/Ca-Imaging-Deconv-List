function y = fn_triggeravg(x,dim,indices,varargin)
% function y = fn_triggeravg(x,dim,indices[,nframes][,'noavg'],['all'])
%---
% average according to triggers
%
% Input:
% - x           data to trigger
% - dim         dimension of the data on which to trigger and average [by
%               default, the last dimension is used]
%               if dim is a vector, the first dimension is taken for
%               triggering, while additional dimensions stand for
%               repetitions
% - indices     trigger position, in indices coordinates; or an array of
%               logicals the same size as x in dimension(s) dim
% - nframes     size of the output in this dimension: it should be a
%               2-element vector (how many frames before trigger, and how
%               many frames after trigger), or a scalar (the same number is
%               used both times) [the default is 0, i.e. only averaging at
%               the trigger positions]
% - 'noavg'     do not average
% - 'all'       keep events that are too close to edges -> NaN will be
%               placed where data is missing

% Thomas Deneux
% Copyright 2008-2017

% Input
nframes = 0;
doavg = true; doall = false;
for k=1:length(varargin)
    a = varargin{k};
    if ischar(a)
        switch a 
            case 'noavg'
                doavg = false;
            case 'all'
                doall = true;
            otherwise
                error argument
        end
    else
        nframes = a;
    end
end
if ~isscalar(dim)
    adddim = dim(2:end);
    dim = dim(1);
else
    adddim = [];
end
if isscalar(nframes), nframes = [nframes nframes]; end

% Sizes
s = size(x);

% Triggers
if islogical(indices)
    sind = size(indices);
    nd = max(length(s),length(sind));
    sind(end+1:nd) = 1;
    s(end+1:nd) = 1;
    dsame = [dim adddim]; done = setdiff(1:nd,dsame);
    if ~all(sind(dsame)==s(dsame)) || ~all(sind(done)==1)
        error 'triggers given as an array of logicals must be the same size as data in the triggering dimension(s), and of size 1 in other dimensions'
    end
    idx = find(indices);
    IDX = cell(1,nd);
    [IDX{:}] = ind2sub(sind,idx);
    nevent = length(IDX{1});
else
    nd = length(s);
    IDX = cell(1,nd);
    IDX{dim} = indices;
    nevent = length(indices);
end
    
% Fill container with all repetitions
y = cell(1,nevent);
subs0 = repmat({':'},1,nd);
for k = 1:nevent
    idxdim = IDX{dim}(k) + (-nframes(1):nframes(2));
    % range goes beyond edges?
    if idxdim(1)<1 || idxdim(end)>s(dim)
        if doall
            error 'not implemented yet'
        else
            continue
        end
    end
    % get the data
    subs = subs0;
    subs{dim} = idxdim;
    for i=adddim, subs{i} = IDX{i}(k); end
    y{k} = subsref(x,substruct('()',subs));
end

% Output
y = cat(nd+1,y{:});
if doavg, y = mean(y,nd+1); end

