function h = fn_hash(inp,varargin)
% function h = fn_hash(input[,meth][,'char|hexa|HEXA|num'][,n])
%---
% This function relies on function hash.m downloaded on Matlab File
% Exchange.
% It extends hash functionalities to structures and cell arrays
% default method 'MD2' is used, input 'n' outputs n letters
% 
% Input:
% - input   Matlab numerical array, cell array, or structure; subelements
%           of cell arrays and structures must themselves be numerical
%           arrays, cell arrays or structures
% - meth    methods, default is 'MD2', see function brick/private/hash.m
% - outtype 'char', 'hexa' or 'num' - indicates whether output will be a
%           number or a word [default='char']
% - n       number of digits of the hexadecimal hash number to return; if
%           n=0, the default value is used (depends on method)
%
% Output:
% - h       the hash key corresponding to input; its value, type and length
%           are controled by parameters meth, outtype and n
%   
% Note that structures with fields in different order give the same hash
% key.

% Michael Kleder (function hash.m)
% Copyright 2005-2007
% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_hash, return, end

meth = 'MD2'; n = 0; outtype = 'char';
for i=1:length(varargin)
    a = varargin{i};
    if ischar(a)
        if fn_ismemberstr(a,{'char' 'hexa' 'HEXA' 'num'})
            outtype = a;
        else
            meth = a;
        end
    else
        n = a;
    end
end

inp = flatten(inp);
h = hash(inp,meth);

% crop to n digits
if n, h = h(1:n); end

% convert output
switch outtype
    case 'hexa'
        % nothing to do
    case 'HEXA'
        h = upper(h);
    case 'char'
        f = (h>='0' & h<='9');
        h(f) = h(f)-'0'+'A';
        h(~f) = h(~f)-'a'+'K';
    case 'num'
        h = hex2dec(h);
end

%---
function inp = flatten(inp)
% transform any Matlab variable to a row vector of uint8

if isempty(inp), inp = {class(inp) size(inp)}; end
inp = row(inp);
if ischar(inp) || islogical(inp)
    inp=uint8(inp);
elseif isnumeric(inp)
    inp=typecast(inp,'uint8');
else
    % convert variable to cell array
    if isstruct(inp)
        inp = orderfields(struct(inp));
        F = fieldnames(inp);
        C = struct2cell(inp);
        C = [F(:); C(:)];
    elseif isobject(inp)
        F = fieldnames(inp); nF = length(F);
        C = cell(nF,1+numel(inp));
        for i=1:nF
            f = F{i};
            C{i,1} = f;
            for j=1:numel(inp)
                C{i,1+j} = inp(j).(f);
            end
        end
        C = C(:);
    elseif iscell(inp)
        C = inp(:);
    else
        error('cannot hash object of class ''%s''',class(inp))
    end
    C = cat(1,C,{class(inp); size(inp)});
    
    % flatten each element of the cell array
    for i=1:numel(C)
        C{i} = flatten(C{i});
    end
    
    % concatenate
    inp = [C{:}];
end

