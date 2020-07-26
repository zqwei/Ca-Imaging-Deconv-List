function s = fn_structmerge(s,varargin)
% function s = fn_structmerge(s,s1[,'skip|strict'][,'recursive'][,'type'][,'i'])
%---
% set or replace values in s from those in s1, where s and s1 are
% structures of the same size
% - if 'skip', or 'strict' flag is specified: does not add new field in
%   structure s (generates error if 'strict' flag and s1 has additional
%   fields)
% - if 'recursive' flag, field values which are themselves structures are
%   not merely replaced, but are also merged using fn_structmerge 
% - if 'type' flag is specified: also requires field values to be the same
%   class in s and s1 when the field already exists in s (generates error
%   if it is not the case, except that it performs the conversions
%   0/1->false/true  and char array->cell array of strings)
% - 'i' flag for 'case insensitive': merge together field names that might
%   differ in case
%
% See also fn_structcat

% Thomas Deneux
% Copyright 2007-2017

% Input
if nargin>=2 && isstruct(varargin{1})
    s1 = varargin{1};
    varargin(1)=[];
else
    s1 = struct(varargin{:});
end
[skip strict recursive type caseinsensitive] = deal(false);
i=0;
while i<length(varargin)
    i = i+1;
    a = varargin{i};
    switch a
        case 'skip'
            skip = true;
        case 'strict'
            strict = true;
        case 'recursive'
            recursive = true;
        case 'type'
            type = true;
        case 'i'
            caseinsensitive = true;
        otherwise
            i = i+1;
            s1.(a) = varargin{i};
    end
end
if isempty(s1), return, end
if any(size(s1)~=size(s))
    if isempty(s)
        s = repmat(fn_structinit(s),size(s1));
    elseif isscalar(s)
        s = repmat(s,size(s1));
    elseif isscalar(s1)
        s1 = repmat(s1,size(s));
    else
        error('size mismatch')
    end
end
skip = skip | strict;

F = fieldnames(s);
F1 = fieldnames(s1);
for k=1:length(F1)
    f1 = F1{k};
    if caseinsensitive
        idx = find(strcmpi(f1,F));
        if isscalar(idx), f=F{idx}; else f=f1; end
    else
        f = f1;
    end
    if skip && ~isfield(s,f)
        if strict
            error('field ''%s'' not present in original structure',f1)
        end
    elseif recursive && isfield(s,f) && isstruct(s(1).(f))
        for i=1:numel(s)
            if isscalar(s1), j=1; else j=i; end
            val = s1(j).(f1);
            if isstruct(val)
                s(i).(f) = fn_structmerge(s(i).(f),val,varargin{:});
            else
                if strict, error('value for field ''%s'' should be a structure',f), end
                s(i).(f) = val;
            end
        end
    else
        for i=1:numel(s)
            if isscalar(s1), j=1; else j=i; end
            if type && isfield(s,f) && ~strcmp(class(s(i).(f)),class(s1(j).(f1)))
                if islogical(s(i).(f)) && isnumeric(s1(j).(f1)) ...
                        && isscalar(s1(j).(f1)) && ismember(s1(j).(f1),[0 1])
                    s(i).(f) = logical(s1(j).(f1));
                elseif iscell(s(i).(f)) && (isempty(s(i).(f)) || ischar(s(i).(f){1})) ...
                        && ischar(s1(i).(f1))
                    s(i).(f) = cellstr(s1(i).(f1));
                else
                    error('class mismatch')
                end
            else
                s(i).(f) = s1(j).(f1);
            end
        end
    end
end