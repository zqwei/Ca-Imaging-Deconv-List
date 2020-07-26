function varargout = fn_sym(varargin)
% function s = fn_sym(a[,uplo])
% function a = fn_sym(s[,uplo])
% function idx = fn_sym(ij[,uplo])
% function idx = fn_sym(i,j[,uplo])
% function [i j] = fn_sym(idx,[,uplo])
% function ij = fn_sym(idx[,uplo])
% converts square (symmetric) matrix to a compact vector
% or inverse conversion
%
% uplo : 'U' [default] or 'L'
% use 'U' to match the C++ implementation

% Thomas Deneux
% Copyright 2003-2017

if nargin==0, help fn_sym, return, end

narg = nargin;
if nargin>1 && ischar(varargin{end})
    uplo = varargin{end};
    narg = narg-1;
else
    uplo = 'U';
end

if narg==1 && ~isvector(varargin{1})        % matrix to vector
    a = varargin{1};
    n=size(a,1);
    if size(a,2)~=n, error('input is not a square matrix'), end
    p=n*(n+1)/2;
    s=zeros(1,p);
    for i=1:n
        if strcmpi(uplo,'L')
            s((i-1)*(2*n-i)/2+(i:n)) = a(i:n,i);
        else
            s((i-1)*i/2+(1:i)) = a(1:i,i);
        end
    end
    varargout = {s};
elseif narg==1 && length(varargin{1})>2     % vector to symmetric matrix
    s = varargin{1};
    p = length(s);
    n = floor((sqrt(1+8*p)-1)/2);
    if n*(n+1)/2~=p, error('input does not match length of symmetric matrix data'), end
    a=zeros(n,n);
    for i=1:n
        if strcmpi(uplo,'L')
            tmp = s((i-1)*(2*n-i)/2+(i:n));
            a(i,i:n) = tmp;
            a(i:n,i) = tmp;
        else
            tmp = s((i-1)*i/2+(1:i));
            a(i,1:i) = tmp;
            a(1:i,i) = tmp;
        end
    end
    varargout = {a};
elseif narg==1 && isscalar(varargin{1})     % vector index to matrix index
    idx = varargin{1};
    if strcmpi(uplo,'U')
        i = round(sqrt(2*idx));
        p = i*(i-1)/2;
        j = idx-p;
    else
        error 'not implemented yet'
    end
    if nargout<=1
        varargout = {[i j]};
    else
        varargout = {i j};
    end
else                                        % matrix index to vector index
    if narg==1
        ij = varargin{1};
        i = ij(1);
        j = ij(2);
    elseif narg==2
        [i j] = deal(varargin{:});
    else
        error argument
    end
    if strcmpi(uplo,'U')
        p = i*(i-1)/2;  % last completed column
        idx = p+j;
    else
        error 'not implemented yet'
    end
    varargout = {idx};
end
    
    
    
    
    
    
    