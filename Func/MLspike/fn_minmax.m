function x = fn_minmax(varargin)
% function fn_minmax(action,x1,x2,..)
%
% utility to easily compute best axes positions...
% 'action' determines what to do :
% - 'minmax'       -> [min(xi(1)) max(xi(2))]
% - 'maxmin'       -> [max(xi(1)) min(xi(2))]
% - 'axu' or 'u'   -> [min max min max ...] (i.e. union of 2 ranges)
% - 'axi' or 'i'   -> [max min max min ...] (i.e. intersection of 2 ranges)
% - logical vector -> 0 for min, 1 for max
% 
% some xi can be empty, or there can be only one x1 which is a matrix, in
% which case min and max operations are performed on its columns

% Thomas Deneux
% Copyright 2006-2017

if nargin==0, help fn_minmax, return, end

action = varargin{1};
if strcmp(action,'axis'), warning('''axis'' flag has been replaced by ''axi'''), action='axi'; end
if nargin>2 || isvector(varargin{2})
    nx = max(fn_itemlengths(varargin(2:end)));
else
    nx = size(varargin{2},1);
end
if ischar(action)
    switch action
        case 'minmax'
            action = [0 1];
        case 'maxmin'
            action = [1 0];
        case {'axu' 'u'}
            action = repmat([0 1],1,nx/2);
        case {'axi' 'i'}
            action = repmat([1 0],1,nx/2);
        otherwise
            error 'unknown flag'
    end
    if nx~=length(action), error 'size mismatch', end
end
if ~all(action==0 | action==1), error('bad action argument'); end

if isvector(action)
    imax = find(action);
    imin = find(~action);
    if nargin>2 || isvector(varargin{2})
        x = NaN(1,nx);
        for i=1:nargin-1 % vectors
            xi = varargin{i+1};
            if isempty(xi), continue, end
            %             if ~any(size(xi)==1) || length(xi)~=length(action)
            %                 error('arguments are not the same length')
            %             end
            x(imin) = min(x(imin),xi(imin));
            x(imax) = max(x(imax),xi(imax));
        end
    else % one matrix
        x1 = varargin{2};
        x = zeros(size(x1,1),1);
        x(imin) = min(x1(:,imin));
        x(imax) = max(x1(:,imax));
    end
else % matrices
    x = zeros(size(action))*nan;
    imax = find(action);
    imin = find(~action);
    for i=1:nargin-1
        xi = varargin{i+1};
        if size(xi)~=size(action)
            error('arguments are not the size')
        end
        x(imin) = min(x(imin),xi(imin));
        x(imax) = max(x(imax),xi(imax));
    end
end
