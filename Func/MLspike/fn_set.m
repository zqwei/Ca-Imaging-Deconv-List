function fn_set(h,varargin)
% function fn_set(hobjs,fields,values)
% function fn_set(hobjs,field1,value1,field2,value2,...)
% function fn_set(hobjs,s)
% function fn_set({hobj1,arg1},{hobj2,arg2},...)
%--- 
% Input:
% - hobjs   vector of nobj graphic handles or object handles
% - fields  cell array of nfield strings, or a single string
% - values  nobj x nfield cell array of values (or 1 x nfiel cell array, or
%           a single value)
% - field1, value1, ...     pairs of field name and values; values can be a
%           vector cell array of length nobj
% - s       structure of length nobj (or scalar structure) and with fields
%           the names of properties to be set
%
% fn_set performs set(hobjs(i),fields{j},values{i,j}) for every possible i
% and j 
% in case of a structure s, performs set(h(i),f{j},x(i).(f{j}))
% 
% fn_set also has some heuristics to set properties that do not exist:
% - setting properties 'xdata', 'ydata' and 'zdata' for object of type
%   'text' actually result in setting its property 'position'
% 
% See also fn_get

% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_set, return, end

% Special multiple calls to fn_set in a single call
if iscell(h)
    args = [{h} varargin];
    for i=1:nargin
        fn_set(args{i}{:})
    end
    return
end

% Input
nobj = numel(h);
% (get input)
switch nargin
    case 1
        return
    case 2 % structure
        x = varargin{1};
        f = fieldnames(x)';
    case 3 % 2 cell arrays for field names and values
        [f x] = deal(varargin{:});
        f = cellstr(f);
    otherwise % syntax: name1, values1, name2, values2, ...
        if mod(length(varargin),2), error 'Invalid parameter/value pair arguments', end
        f = varargin(1:2:end);
        x = varargin(2:2:end);
end
nfield = length(f);
% (convert cell format to structure)
if ~isstruct(x)
    % prepare
    if ~iscell(x), x = {x}; end
    if isscalar(x)
        x = repmat(x,[1 nfield]);
    elseif isvector(x) 
        if length(x)==nfield
            % the desired cell format - nothing to do
        elseif length(x)==nobj && nfield==1
            x = {x};
        else
            error 'cell argument must be of a vector of length nfield or an array of size nobj x nfield'
        end
    else
        if isequal(size(x),[nobj nfield])
            x = num2cell(x,1);
        elseif isequal(size(x),[nfield nobj])
            x = num2cell(x,2);
        else
            error 'cell argument must be of a vector of length nfield or an array of size nobj x nfield'
        end
    end
    % color: convert array to cell array
    icol = fn_find(strfind(lower(f),'color')); % indices of field names containing 'color'
    for i = icol
        if nobj>1 && ~iscell(x{i})
            xi = x{i};
            if ischar(xi) && length(xi)==nobj && all(ismember(xi,'wkbrgmyc'))
                % e.g. fn_set([hl1 hl2],'color','br')
                x{i} = num2cell(xi);
            elseif isnumeric(xi) && size(xi,1)==nobj
                % e.g. fn_set([hl1 hl2],'color',[0 0 1; 1 0 0])
                x{i} = row(num2cell(xi,2));
            end
        end
    end
    % convert
    x = [row(f); row(x)];
    x = struct(x{:});
end
% (make the structure length nobj)
if isscalar(x), x = repmat(x,1,nobj); end

% Set properties
ok = true;
for i=1:nobj
    if h(i)==0, continue, end
    for j=1:nfield
        fj = f{j};
        xij = x(i).(fj);  
        if isprop(h(i),fj)
            set(h(i),fj,xij); 
        elseif fn_ismemberstr(f{j},{'xdata' 'ydata' 'zdata'}) &&  strcmp(get(h(i),'type'),'text')
            % some heuristics to 'guess' the undefined property
            pos = get(h(i),'pos');
            pos(fn_switch(f{j}(1),'x',1,'y',2,'z',3)) = xij;
            set(h(i),'pos',pos)
        elseif strcmp(f{j},'color') && fn_ismemberstr(get(h(i),'type'),{'patch' 'rectangle'})
            set(h(i),'edgecolor',xij)
        elseif strcmp(f{j},'appdata')
            if isempty(xij), xij = struct; end
            F = fieldnames(xij);
            xij0 = getappdata(h(i));
            F0 = fieldnames(xij0);
            F0 = setdiff(F0,F);
            for k=1:length(F0)
                rmappdata(h(i),F0{k});
            end
            for k=1:length(F)
                fk = F{k};
                setappdata(h(i),fk,xij.(fk))
            end
        else
            ok = false;
        end
    end
end
if ~ok
    disp 'some properties could not be set'
end

