function whoisbig(varargin)
% function whoisbig([var][,minsize])
%---
% Input:
% - var     a variable or a structure [default: all variables in caller
%           workspace]
% - minsize e.g.: 10M [default], G, 100k, 0

% Thomas Deneux
% Copyright 2015-2017

% Input
var = []; minsize = [];
for k=1:length(varargin)
    a = varargin{k};
    if isequal(a,0)
        minsize = a;
    elseif ischar(a)
        tokens = regexpi(a,'^([\d.]*)([KMG]{0,1})B{0,1}$','tokens');
        if ~isempty(tokens)
            [n u] = deal(tokens{1}{:});
            minsize = fn_switch(isempty(n),1,str2double(n)) * 2^fn_switch(lower(u),'',0,'k',10,'m',20,'g',30);
        else
            try
                varname = a;
                var = evalin('caller',varname);
            catch
                error(['cannot interpret argument ''' a ''''])
            end
        end
    else
        var = a;
        varname = inputname(k);
    end
end
if isempty(minsize)
    if isempty(var)
        minsize = 10*2^20; % '10M' 
    else
        w = whos('var');
        totsize = w.bytes;
        minsize = min(10*2^20,totsize/1000);
    end
end

%% call 'whos'
incaller = isempty(var);
if incaller
    % check caller workspace
    w = evalin('caller','whos');
else
    if isobject(var) && ~isvalid(var)
        disp 'Invalid or deleted object'
        return
    elseif isstruct(var) || isobject(var)
        % check fields of structure
        F = fieldnames(var);
        for i=1:length(F)
            f = F{i};
            eval([f ' = var.' f ';'])
        end
        w = whos(F{:});
    else
        % check variable
        if isempty(varname)
            varname = 'var';
        else
            eval([varname ' = var;'])
        end
        w = whos(varname);
    end
end

%% sort
[~, ord] = sort([w.bytes]);
w = w(ord);

%% subselect

% (check which variable's size exceed threshold)
ok = ([w.bytes]>=minsize);

% (add also object which might be container of large variables through handles)
matlabclasses = {'logical' 'char' 'single' 'double' 'uint8' 'uint16' 'uint32' 'uint64' 'int8' 'int16' 'int32' 'int64' 'struct' 'cell'};
okclasses = [matlabclasses 'alias'];
for k = find(ok & ~ismember({w.class},okclasses))
    % add variables who are small but which, because they are handle
    % object, could in fact contain large objects
    if incaller
        vark = evalin('caller',w(k).name);
    elseif isstruct(var) || isobject(var)
        vark = var.(w(k).name);
    else
        vark = var;
    end
    ok(k) = ~isgraphics(vark) && isvalid(vark);
end
if ~any(ok)
    fprintf('no variable is big (total: %iKB)\n',round(sum([w.bytes])/2^10))
    return
end
w = w(ok);
n = length(w);

%% name
names = char('Name','',w.name);

%% size
s1 = fliplr(char(fn_map(@(x)fliplr(num2str(x(1))),{w.size},'cell')));
s2 = char(fn_map(@(s)fn_strcat(s(2:end),'x','x',''),{w.size},'cell'));
sizes = char('Size','',[s1 s2]);

%% class
classes = char('Class','',w.class);

%% bytes
bytes = [w.bytes];
bk = min(floor(log(bytes)/log(1024)),3);
bs = bytes./(1024.^bk);
mem = cell(1,n);
for i=1:n
    switch bk(i)
        case 0
            mem{i} = num2str(bs(i));
        case 1
            mem{i} = [num2str(round(bs(i))) 'k'];
        case 2
            mem{i} = [num2str(round(bs(i))) 'M'];
        case 3
            mem{i} = [num2str(bs(i),'%.1f') 'G'];
    end
end
ll = fn_map(@length,mem);
L = max(ll);
for i=1:n, mem{i} = [repmat(' ',1,L-ll(i)) mem{i}]; end
mem = char('Memory','',mem{:});

%% space
sp = repmat(' ',2+n,2);

%% display
disp([sp names sp mem sp sizes sp classes])
fprintf('\n')

