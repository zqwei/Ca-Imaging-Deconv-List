function m =fn_mean(x,dim,varargin)
% function m = fn_mean(x[,dim[,'squeeze'|reshapepermute arg.]])
%---
% dim can be a set of several dimensions [default: all dimensions]
% if additional arguments are defined, the result of averaging is sent to
% fn_reshapepermute with these arguments

% Thomas Deneux
% Copyright 2015-2017

if nargin<2
    m = mean(x(:));
    return
end

m = x;
for d=dim
    m = mean(m,d);
end

if nargin>=3 
    if nargin==3 && strfind('squeeze',varargin{1})
        m = squeeze(m);
    else
        m = fn_reshapepermute(m,varargin{:});
    end
end
