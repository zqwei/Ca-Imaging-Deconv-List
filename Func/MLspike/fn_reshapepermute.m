function y = fn_reshapepermute(x,varargin)
% function y = fn_reshapepermute(x,dimshift)
% function y = fn_reshapepermute(x,resh,dimshift)
% function y = fn_reshapepermute(x,resh,perm[,resh2])
%---
% perform a combination of reshape and permute from a single function
%
% Input:
% - x           input array
% - dimshift    cell array - shows which dimensions will appear together
%               for example, fn_reshapepermute(x,{2 [1 3]}) is equivalent
%               to rehape(permute(x,[2 1 3]),[size(x,2) size(x,1)*size(x,3)])
% - resh, perm, resh2  
%               vectors - reshaping and permuting vectors to be applied one
%               after the other
%
% Output:
% - y           output array

% Thomas Deneux
% Copyright 2010-2017

if nargin==0, help fn_reshapepermute, end

% Input
dimshift = []; resh2 = [];
if nargin<2
    error argument
elseif nargin==2
    resh1 = [];
    dimshift = varargin{1};
    if ~iscell(dimshift), error '''dimshift'' must be a cell array', end
else
    resh1 = varargin{1};
    if iscell(varargin{2})
        dimshift = varargin{2};
        if nargin>3, error 'argument', end
    else
        perm = varargin{2};
        if nargin==4, resh2 = varargin{3}; end
    end
end
        
% Convert cell array 'dimshift' into permutation+reshape
if ~isempty(dimshift)
    if isempty(resh1), s = size(x); else s = resh1; end
    s(end+1:max([dimshift{:}])) = 1;
    if numel(s)>length([dimshift{:}]), dimshift{end+1} = setdiff(1:numel(s),[dimshift{:}]); end % add missing dimensions at the end
    perm = [dimshift{:}];
    ndimnew = length(dimshift);
    resh2 = ones(1,max(2,ndimnew));
    for i=1:ndimnew, resh2(i) = prod(s(dimshift{i})); end
end

% Perform operations
y = x;
if ~isempty(resh1), y = reshape(y,resh1); end
if ~isempty(perm),  y = permute(y,perm);  end
if ~isempty(resh2), y = reshape(y,resh2); end

