function data=fn_enlarge(data,varargin)
% function data=fn_enlarge(data,fact)
% function data=fn_enlarge(data,size[,outsideval])
% function data=fn_enlarge(data,fact,size[,outsideval])
%---
% Enlarge data by factor 'fact' or so as to fit new size 'size'.
% 
% Input:
% - data        array
% - fact        vector - by how much to enlarge in each dimension; if its
%               length is less than the number of dimensions of data, only
%               these first dimensions are affected; except if fact is a
%               scalar: in such case it is applied to the first 2
%               dimensions of data
% - size        vector - new desired size for the data; if its length is
%               less than the number of dimensions of data, only these
%               first dimensions are affected 
% - outsideval  scalar or flag such as 'mean', 'min', 'max' - value to put
%               in extra space in case that new size is not a perfect
%               multiple of the original size [default: NaN]
%
% Note that the function guesses whether to interpret its second argument
% as 'fact' or 'size'. It chooses 'size' if all elements of the vector are
% larger than the size of data in the corresponding dimensions.
%
% See also fn_bin

% Thomas Deneux
% Copyright 2012-2017

if nargin==0, help fn_enlarge, return, end

% input
oldsize = size(data);
if length(varargin)>=2 && ~isscalar(varargin{2})
    [fact newsize] = deal(varargin{1:2});
    ndim = max([length(fact) length(newsize) length(oldsize)]);
    oldsize(end+1:ndim) = 1;
    fact(end+1:ndim) = 1;
    newsize(end+1:ndim) = oldsize(end+1:ndim);
    newsize0 = oldsize.*fact;
    if length(varargin)<3
        outsideval = fn_switch(islogical(data),false,NaN); 
    else
        outsideval = varargin{3};
        if ischar(outsideval), outsideval = feval(outsideval,data(:)); end
    end
else
    sizeorfact = varargin{1};
    n = length(sizeorfact);
    oldsize(end+1:n) = 1;
    ndim = length(oldsize);
    if all(sizeorfact>=oldsize(1:n))
        newsize = sizeorfact;
        newsize(n+1:ndim) = oldsize(n+1:ndim);
        fact = floor(newsize./oldsize);
        newsize0 = oldsize.*fact;
        if length(varargin)<2
            outsideval = fn_switch(islogical(data),false,NaN);
        else
            outsideval = varargin{2};
            if ischar(outsideval), outsideval = feval(outsideval,data(:)); end
        end
    else
        fact = sizeorfact;
        if isscalar(fact), fact = [fact fact]; end
        fact(end+1:ndim) = 1;
        newsize0 = oldsize.*fact;
        newsize = newsize0;
    end
end

% enlarge
if all(newsize==oldsize)
    return
elseif isempty(data)
    if prod(newsize)==0, data = reshape(data,newsize); end
    return
else
    data = reshape(data,fn_interleave(2,ones(1,ndim),oldsize));
    data = repmat(data,fn_interleave(2,fact,ones(1,ndim)));
    data = reshape(data,newsize0);
    if ~all(newsize==newsize0)
        data0 = data;
        if islogical(data)
            if outsideval
                data = true(newsize);
            else
                data = false(newsize);
            end
        else
            data = ones(newsize)*outsideval;
        end
        c = cell(1,ndim);
        for k=1:ndim, c{k} = 1:newsize0(k); end
        s = substruct('()',c);
        data = subsasgn(data,s,data0);
    end
end
