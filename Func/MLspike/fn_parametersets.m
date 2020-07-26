function x = fn_parametersets(varargin)
% function x = fn_parametersets(s)
% function x = fn_parametersets('fieldname1',{values1a values1b...},'fieldname2',{values2a values2b ...},...)

% Thomas Deneux
% Copyright 2015-2017

% build initial structure
if nargin==1
    s = varargin{1};
else
    if mod(nargin,2), error 'incorrect parameter name/value pairs', end
    for i=2:2:nargin, varargin{i} = varargin(i); end
    s = struct(varargin{:});
end
if ~isvector(s), error 'original structure must be scalar or vector', end
       
% analyze the original structure
nsubset = length(s);
F = fieldnames(s);
nfield = length(F);

% fill-in the output structure
x = cell(1,nsubset);
for isubset = 1:nsubset
    si = s(isubset);
    nperfield = zeros(1,nfield);
    for ifield=1:nfield
        f = F{ifield};
        if ischar(si.(f)), si.(f) = {si.(f)}; end % consider string as a single entry rather than as an array or characters
        nperfield(ifield) = length(si.(f)); 
    end
    nseti = prod(nperfield);
    xi = repmat(si,1,nseti);
    for k=1:nseti
        ij = fn_indices(nperfield,k);
        for ifield=1:nfield
            f = F{ifield};
            if iscell(si.(f))
                xi(k).(f) = si.(f){ij(ifield)};
            else
                xi(k).(f) = si.(f)(ij(ifield));
            end
        end
    end
    x{isubset} = xi;
end
x = [x{:}];
if nsubset==1
    x = reshape(x,nperfield);
end

        
