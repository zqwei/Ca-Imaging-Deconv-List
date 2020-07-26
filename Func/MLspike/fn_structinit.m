function s = fn_structinit(varargin)
% function s = fn_structinit([model,][siz])
% function s = fn_structinit([model,][s1,s2,...])
%---
% Initializes a structure with no fields (or with same fields as a model)
% and of size siz.
% If size is a scalar n, the structure will be a row vector of length n.

% Thomas Deneux
% Copyright 2015-2017

% input
if isstruct(varargin{1})
    model = varargin{1};
    varargin(1) = [];
else
    model = [];
end
switch length(varargin)
    case 0
        siz = 1;
    case 1
        siz = varargin{1};
    otherwise
        siz = [varargin{:}];
end

% initialize structure
if ~isstruct(model)
    s = struct;
else
    C = row(fieldnames(model)); [C{2,:}] = deal([]);
    s = struct(C{:});
end
if isscalar(siz)
    s = repmat(s,[1 siz]);
else
    s = repmat(s,siz);
end
