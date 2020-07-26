function y = fn_subsref(x,varargin)
% function B = fn_subsref(A,idx1,idx2,...)
% function indices = fn_subsref(siz,idx1,idx2,...[,'global|local'])
%---
% 
% Input:
% - A/siz       array, or size of an array (the function guesses that it is
%               a size vector if the argument is a vector of size less than
%               or equal to 5, therefore, an array A should be larger than
%               this)
% - idx1, ...   indices in the successive dimensions; can be either numeric
%               values (the indices themselves) or strings that are
%               interpreted (such as ':', '1:3', '1 3:4', etc.)
%               the number of indices specification must be one or the
%               number of dimensions of A / the length of siz
% - 'global|local'  indicates whether the output indices should be a vector
%               of global indices [default behavior], or a cell array of
%               indices for each coordinates
%
% Output:
% - B/indices   sub-array formed by the elements of A specified by the
%               indices idx1, ..., or indices formatted as 'global' or
%               'local'
%
% Examples:
% - fn_subsref([1 2 3; 4 5 6],':',2:3)   returns the sub-array [2 3; 5 6]
% - fn_subsref([1 2 3; 4 5 6],'1','1 3') returns the sub-array [1 3]
% - fn_subsref([2 3],'1','1 3','local')  returns the indices {[1] [1 3]}
% - fn_subsref([2 3],'1','1 3')          returns the indices [1 5]
%
% See also fn_indices, cellpop

% Thomas Deneux
% Copyright 2006-2017

% Input
argisarray = ~isnumeric(x) || ~isvector(x) || length(x)>5;
if argisarray
    A = x;
    siz = size(A);
else
    siz = x;
end
if ischar(varargin{end}) && ismember(varargin{end},{'global' 'local'})
    indformat = varargin{end};
    indices = varargin(1:end-1);
else
    indformat = 'global';
    indices = varargin;
end
if isscalar(indices), siz = prod(siz); end
if length(indices) ~= length(siz)
    error('the number of indices specification must be one or the number of dimensions of A / the length of siz')
end

% Interpret indices
for k=1:length(indices)
    idx = indices{k};
    if ~ischar(idx), continue, end
    if strcmp(idx,':')
        indices{k} = 1:siz(k);
    else
        ii = 1:siz(k); %#ok<NASGU>
        indices{k} = eval(['ii([' idx '])']);
    end
end

% Output
if argisarray
    B = subsref(A,struct('type','()','subs',{indices}));
    y = B;
else
    if strcmp(indformat,'global')
        if isscalar(siz)
            indices = indices{1}; % pas besoin de se faire chier!
        else
            A = reshape(1:prod(siz),siz);
            B = subsref(A,struct('type','()','subs',{indices}));
            indices = B(:)';
        end
    end
    y = indices;
end

