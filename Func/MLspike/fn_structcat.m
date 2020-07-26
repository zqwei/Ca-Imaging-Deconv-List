function S = fn_structcat(varargin)
% function S = fn_structcat(s1,s2,...,'skip|strict')
% function S = fn_structcat({s1,s2,...},'skip|strict')
%---
% Concatenate structures with possible different field names, either by
% adding fields [default], or by removing fields absent from at least one
% argument ('skip' flag; 'strict' generates an error if fields are not the
% same)
%
% See also fn_structmerge

% Thomas Deneux
% Copyright 2015-2017

% Input
if iscell(varargin{1})
    s = varargin{1};
else
    s = {};
    while ~isempty(varargin) && isstruct(varargin{1})
        s = [s varargin(1)];
        varargin(1) = [];
    end
end
if ~isempty(varargin)
    mode = varargin{1};
else
    mode = 'merge';
end

% New list of fields
n = length(s);
F = fieldnames(s{1});
for i=1:n
    F1 = fieldnames(s{i});
    switch mode
        case 'merge'
            F = union(F,F1);
        case 'skip'
            F = intersect(F,F1);
        case 'strict'
            if any(setxor(F,F1))
                error 'Structures do not have the same fields'
            end
    end
end
nF = length(F);

% Perform the concatenation
S = cell2struct(cell(nF,n),F);
for i=1:n
    si = s{i};
    Si = S(i);
    if strcmp(mode,'merge')
        F1 = fieldnames(si);
    else % skip
        F1 = F;
    end
    for k=1:length(F1)
        f = F1{k};
        Si.(f) = si.(f);
    end
    S(i) = Si;
end







