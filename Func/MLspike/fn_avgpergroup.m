function [averages nrep] = fn_avgpergroup(data,conds,dim,varargin)
% function [averages nrep] = fn_avgpergroup(data,conds,dim[,nrepmax][,fun])
%---
% average individual groups separately in a dataset that splits into
% several groups
% 
% Input:
% - data        ND array 
% - conds       a vector of length size(data,dim) - indicates to which
%               group does belong each repetition along dimension dim
% - dim         the dimension on which to operate averaging
% - nrepmax     (optional) the maximal number of repetitions to use for
%               each group: if a group has more repetitions, the extra ones
%               are ignored; if a group has less, an error is generated.
%               Use flag 'same' to use the number of repetitions of the
%               smallest group.
% - fun         Function to apply: can be 'mean' [default], 'sum', 'rms',
%               'std', 'var', 'mode', 'median', 'min', 'max'
%
% Output:
% - averages    ND array, its size in dimension dims is the number of
%               groups (i.e. length(unique(conds)) ), sizes in all other
%               dimensions are identical to those of data
%
% See also fn_arrangepercond

% Thomas Deneux
% Copyright 2015-2017

% input
fun = 'mean'; nrepmax = 0;
k = 0;
while k<length(varargin)
    k = k+1;
    a = varargin{k};
    if ischar(a)
        fun = a;
    else
        nrepmax = a;
    end
end

% sizes
s = size(data);
if isvector(data) && nargin<3, dim = find(s~=1); end


if iscell(conds) && isnumeric(conds{1})
    groups = conds(:);
    ngroup = length(groups);
else
    % TODO: code does not match code of fn_arrangepergroup
    if ~isvector(conds) || length(conds)~=s(dim)
        error 'length of ''conds'' does not match size of ''data'' in dimension ''dim'''
    end
    u = unique(conds);
    ngroup = length(u);
    groups = cell(1,ngroup);
    for i=1:ngroup, groups{i} = find(conds==u(i)); end
end
npergroup = fn_itemlengths(groups);


% if nargout<2, disp(['number of repetitions per group: ' num2str(npergroup,' %i')]), end
if nrepmax == 0;
    nrep = npergroup;
elseif ischar(nrepmax)
    if ~strcmp(nrepmax,'same'), error('invalid flag ''%s''',nrepmax), end
    nrepmax = min(npergroup);
    nrep = nrepmax;
else
    if any(npergroup<nrepmax), error 'some group do not have enough elements', end
    nrep = nrepmax;
end
if nrepmax && nargout<2
    disp(['-> keep ' num2str(nrep) ' repetitions'])
end

% average
averages = cell(1,ngroup);
subs = repmat({':'},[1 length(s)]);
for i=1:ngroup
    if nrepmax
        subs{dim} = groups{i}(1:nrepmax);
    else
        subs{dim} = groups{i};
    end
    switch fun
        case {'mean' 'median' 'mode' 'rms' 'sum'}
            averages{i} = feval(fun,fn_subsref(data,subs{:}),dim);
        case {'std' 'var' 'min' 'max'}
            averages{i} = feval(fun,fn_subsref(data,subs{:}),[],dim);
        otherwise
            error('operation ''%s'' not handled',fun)
    end
end
averages = cat(dim,averages{:});


