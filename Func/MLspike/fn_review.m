function fn_review(x,varargin)
% function fn_review(x[,command][,'in',hf])
%---
% opens a new figure and displays one of the datas xk (change k by pressing
% arrows); if there is only one data x, switches between subdata according
% to the following rules:
% - if x is a structure or an object, uses xk = x(k) [k can be multidimensional index]
% - if x is a cell array, uses xk = x{k} [idem]
% - if x is an array, uses xk = x(:,..,k), operating on the last dimension
%
% if there is a command argument, executes the custom command instead
% of the default
% [technical note: the custom command can be either
%  - a character array to be evaluated in base workspace using variable 'x'
%  - or a function handle - fuction should have 1 argument]
% 
% the default command is @showrew, file fn_review_showres.m can be edited to change
% the behaviour
%
% see also fn_review_showres

% Thomas Deneux
% Copyright 2005-2017

if nargin==0, help fn_review, return, end

% Input
% (x)
if iscell(x)
    % X is already a good boy
elseif isstruct(x) || isobject(x)
    x = num2cell(x);
elseif isnumeric(x)
    x = num2cell(x,1:ndims(x)-1);
else
    error('single data argument must be a cell array or struct array')
end
% (other arguments)
command = 'default';
hf = 797;
k = 0;
while k<length(varargin)
    k = k+1;
    a = varargin{k};
    if ischar(a) && strcmp(a,'in')
        k = k+1;
        hf = varargin{k};
    elseif ischar(a) || isa(a,'function_handle')
        command = a;
    else
        error argument
    end
end
    
[ni nj nk] = size(x); % important to do like this in case ndims(X)>3
s = [ni nj nk];
singleelem = false;
switch sum((s>1).*[1 2 4])
    case 0
        disp('fn_review: only one element')
        singleelem = true;
        d = find(s>1,1,'first');
        dims = [1 1 1];
        show = 1;
        fact = [1 1 1];
    case {1,2,4}    % vector
        d = find(s>1,1,'first');
        dims = [d d d];
        show = d;
        fact = [10 1 100];
    case 7          % 3D
        dims = [1 2 3];
        show = [1 2 3];
        fact = [1 1 1];
    case 3          % 2D
        if s(1)>=s(2)
            dims = [1 2 1];
        else
            dims = [1 2 2];
        end
        show = [1 2];
        fact = [1 1 10];
    otherwise
        error('stupid size')
end

% init
figure(hf)
set(hf,'numbertitle','off','name','fn_review')
clf(hf), fn_figmenu(hf)
info = struct('X',{x},'idx',[1 1 1], ...
    's',s,'dims',dims,'show',show,'fact',fact,'command',command, ...
    'hf',hf,'ha',axes('parent',hf));
setappdata(hf,'fn_review',info)

if ~singleelem
    set(hf,'WindowKeyPressFcn',@keypress,'WindowScrollWheelFcn',@keypress)
end

evalcommand(info)

%---
function keypress(hf,evnt)

info = getappdata(hf,'fn_review');
if isa(evnt,'matlab.ui.eventdata.ScrollWheelData') || isfield(evnt,'VerticalScrollCount')
    d = 1;
    step = evnt.VerticalScrollCount;
else
    step = []; 
    switch evnt.Key
        case {'leftarrow','rightarrow'}
            d = 2;
            step = 1-2*strcmp(evnt.Key,'leftarrow');
        case {'uparrow','downarrow'}
            d = 1;
            step = 1-2*strcmp(evnt.Key,'uparrow');
        case {'pageup','pagedown'}
            d = 3;
            step = 1-2*strcmp(evnt.Key,'pageup');
        case 'c'
            if strcmp(evnt.Modifier,'control'), close(hf), end
            return
        case {'r' 'space'} % repeat
            evalcommand(info)
            return
        case 'home'
            info.idx(:) = 1;
        case 'end'
            info.idx = info.s;
        case 'g'
            % "goto"
            if sum(info.s>1)==1
                % move only in one dimension
                idx = fn_input('go to index',fn_indices(info.s,info.idx), ...
                    ['stepper 1 1 ' num2str(prod(info.s)) ' 1 %i']);
                if isempty(idx), return, end
                info.idx = fn_indices(info.s,idx);
            else
                % general case
                s = struct( ...
                    'i',{info.idx(1) ['stepper 1 1 ' num2str(info.s(1)) ' 1 %i']}, ...
                    'j',{info.idx(2) ['stepper 1 1 ' num2str(info.s(2)) ' 1 %i']}, ...
                    'k',{info.idx(3) ['stepper 1 1 ' num2str(info.s(3)) ' 1 %i']} ...
                    );
                s = fn_structedit(s);
                if isempty(s), return, end
                info.idx = [s.i s.j s.k];
            end
        case 'f'
            % "fast goto"
            idx = fn_input('go to index',fn_indices(info.s,info.idx), ...
                ['slider 1 ' num2str(prod(info.s)) ' 1']);
            if isempty(idx), return, end
            info.idx = fn_indices(info.s,idx);
        case 'd' 
            % "défilé"
            while true
                d = 2;
                step = 1-2*strcmp(evnt.Key,'leftarrow');
                step = step*info.fact(d);
                d = info.dims(d);
                info.idx(d) = 1+mod((info.idx(d)-1)+step,info.s(d));
                setappdata(hf,'fn_review',info)
                evalcommand(info);
                pause(.05)
            end
        otherwise
            return
    end
    if ~isempty(step), step = step*info.fact(d); end
end
if ~isempty(step)
    d = info.dims(d);
    info.idx(d) = 1+mod((info.idx(d)-1)+step,info.s(d));
end

setappdata(hf,'fn_review',info)

evalcommand(info);

%---
function evalcommand(info)

try
    idx = info.idx;
    x = info.X{idx(1),idx(2),idx(3)};
    if ishandle(info.ha), axes(info.ha), end
    if isa(info.command,'function_handle')
        info.command(x);
    elseif strcmp(info.command,'default')
        fn_review_showres(x,info)
    else
        assignin('base','x',x)
        evalin('base',info.command)
        axis(info.ha,'tight')
    end
    if ishandle(info.ha)
        title(info.ha,num2str(info.idx(info.show)))
    else
        set(info.hf,'name',['fn_review [' num2str(info.idx(info.show)) ']'])
    end
catch ME
    disp(['Error in fn_review display: ' ME.message])
    if ishandle(info.ha)
        title(info.ha,[num2str(info.idx(info.show)) ' [ERROR OCCURED]'])
    else
        set(info.hf,'name',['fn_review [' num2str(info.idx(info.show)) ' -> ERROR OCCURED]'])
    end
end
