function [data1 npergroup] = fn_arrangepergroup(data,conds,dim,varargin)
% function [data1 npergroup] = fn_arrangepergroup(data,conds,dim[,'all'][,subconds])
%---
% average individual groups separately in a dataset that splits into
% several groups
% 
% Input:
% - data        ND array 
% - conds       a vector of length size(data,dim) - indicates to which
%               group does belong each repetition along dimension dim
%               alternatively, a cell array of vectors of indices can be
%               used that directly specifies which indices to take for each
%               group
% - dim         the dimension for conditions / repetitions
% - 'same'/'all'    if 'same' [=default], the minimal number of repetitions
%               accross all conditions will be used (possible extra
%               repetitions for other conditions will be ignored); if
%               'all', the maximal number of repetitions will be used
%               (NaN will be placed for missing repetitions of conditions
%               that have less repetitions)
% - subconds    make only these conditions appear; if some conditions in
%               'subconds' are not present in 'conds', the default flag is
%               set to 'all' instead of 'same'
%
% Output:
% - data1       (N+1)D array: the former dimension for conditions /
%               repetitions will be split between conditions and repetition
%               (an extra dimension will be inserted just after 'dim')
% - npergroup   number of repetition for each group (all equal if 'same')
%
% See also fn_avgpercond

% Thomas Deneux
% Copyright 2015-2017

% Input
s = size(data);
if isvector(data) && nargin<3, dim = find(s~=1); end
flag = 'default'; subconds = [];
for i=1:length(varargin)
    a = varargin{i};
    if ischar(a)
        flag = a;
    else
        subconds = a;
    end
end

% Define groups
if iscell(conds) && isnumeric(conds{1})
    groups = conds(:);
    if ~isempty(subconds), groups = groups(subconds); end
    ngroup = length(groups);
else % TODO: code below seems not to handle all cases, and does not match code in fn_avgpergroup
    % input
    if ~(isempty(conds) || isvector(conds)) || length(conds)~=s(dim)
        error '''conds'' must be either a vector cell array, or a vector  of length matching size of ''data'' in dimension ''dim'''
    end
    if isempty(subconds), subconds = unique(conds); end

    % groups (first convert to categorical Matlab data type)
    try
        conds = categorical(conds,subconds);
        subconds = categorical(subconds);
    catch
        % old Matlab versions
        if ~isnumeric(conds)
            error 'cannot handle non-numeric categories with present Matlab version'
        end
    end
    ngroup = length(subconds);
    groups = cell(1,ngroup);
    for i=1:ngroup, groups{i} = find(conds==subconds(i)); end
end

% Determine a common number of repetition for every group
npergroup = fn_itemlengths(groups);
if any(npergroup==0)
    if strcmp(flag,'default')
        flag = 'all';
    elseif strcmp(flag,'same')
        error 'some values are not found in the data, using flag ''same'' will result in an empty output'
    end
elseif strcmp(flag,'default')
    flag = 'same';
end
nrep = fn_switch(flag,'same',min(npergroup),'all',max(npergroup));

% Rearrange
s1 = [s(1:dim-1) ngroup nrep s(dim+1:end)];
if iscell(data)
    data1 = cell(s1);
elseif isnumeric(data)
    switch class(data)
        case {'single' 'double'}
            data1 = NaN(s1,'like',data);
        otherwise
            data1 = zeros(s1,'like',data);
    end
else
    error argument
end
subs = substruct('()',repmat({':'},[1 length(s)]));
subs1 = substruct('()',repmat({':'},[1 length(s1)])); 
for i=1:ngroup
    subs1.subs{dim} = i;
    if npergroup(i)==nrep
        subs.subs{dim} = groups{i};
        subs1.subs{dim+1} = ':';
    elseif npergroup(i)<nrep
        subs.subs{dim} = groups{i};
        subs1.subs{dim+1} = 1:npergroup(i);
    elseif npergroup(i)>nrep
        subs.subs{dim} = groups{i}(1:nrep);
        subs1.subs{dim+1} = ':';
    end
    data1 = subsasgn(data1,subs1,subsref(data,subs));
end


