function indices = fn_listedit(varargin)
% function indices = fn_listedit(A[,B...][,indices])
%---
% Manually select and reorder items in one or multiple lists (in the case
% of multiple lists, the item are aligned in a single table).
% 
% Input:
% - A,B,...     numerical or cell array - a list
% 
% Output:
% - indices     an m*n array, where n is the number of lists and m the
%               number of kept items in the lists - the indices of kept
%               items from all lists

% Thomas Deneux
% Copyright 2015-2017

if nargin==0
    varargin = {num2cell('a':'z') {'hello' 'kitty'}};
end

% Use a pointer to pass information
P = fn_pointer;

% Init lists and indices
initdata(P,varargin)

% Graphic display
makegui(P)

% Set callbacks
setcallbacks(P)

% Draw table
displaytable(P,true)

% Wait for ok press
waitfor(P.grob.ok)
indices = P.indices(P.valid==1,:);

function initdata(P,lists)

P.lists = lists;
P.nlist = length(P.lists);
for i=1:P.nlist
    if ~iscell(P.lists{i}), P.lists{i} = num2cell(P.lists{i}); end
end
P.nperlist = fn_map(@length,P.lists);
P.columns = fn_map(@(i)[(1:P.nperlist(i))' ones(P.nperlist(i),1)],1:P.nlist,'cell');
columns2table(P)
% P.m = min(P.nperlist); P.M = max(P.nperlist);
% P.indices = zeros(P.M,P.nlist);
% for i=1:P.nlist, P.indices(1:P.nperlist(i),i) = (1:P.nperlist(i)); end
% P.valid = [ones(P.m,1); 2*ones(P.M-P.m,1)];
P.cursel = [];

function makegui(P)

g = struct;
g.hf = figure('integerhandle','off','numbertitle','off','name','List Edit');
g.list = uitable;
names = {'top' 'up x10' 'up' 'down' 'down x10' 'bottom'};
for i=1:6
    g.buttons(i) = uicontrol('string',names{i});
end
g.ok = uicontrol('string','OK');
P.grob = g;

fposname = [fn_fileparts(which('fn_listedit'),'noext') '.mat'];
fn_framedesign(g,fposname);
set([g.list g.buttons g.ok],'units','normalized')

function setcallbacks(P)

g = P.grob;

% Buttons
set(g.ok,'callback',@(u,e)delete(g.hf))
set(g.buttons,'callback',@(u,e)moveitems(P,get(u,'string')))

% Table
set(g.list,'cellselectioncallback',@(u,e)setfield(P,'cursel',e.Indices)) %#ok<SFLD>
set(g.list,'buttondownfcn',@(u,e)changevalid(P))

function displaytable(P,firsttime)

if nargin<2, firsttime = false; end

if firsttime
    %listnames = num2cell(char('A'+(0:P.nlist-1)));
    exnames = cell(1,P.nlist); 
    for i=1:P.nlist, exnames{i} = P.lists{i}{1}; end
    set(P.grob.list,'columnname',['idx' exnames])
    set(P.grob.list,'columnformat',repmat({'char'},[1 1+P.nperlist]))
    set(P.grob.list,'columnwidth',[{30} repmat({'auto'},[1 P.nlist])])
end

M = length(P.valid);
data = cell(M,1+P.nlist);
kvalid = 0;
for j=1:M
    if P.valid(j)==1
        kvalid = kvalid+1;
        data{j,1} = kvalid;
    end
    for i=1:P.nlist
        idx = P.indices(j,i);
        if idx~=0
            switch P.valid(j)
                case 0
                    data{j,1+i} = ['[' P.lists{i}{idx} ']'];
                case 1
                    data{j,1+i} = P.lists{i}{idx};
                case 2
                    data{j,1+i} = [P.lists{i}{idx} '?'];
            end
        end
    end
end
set(P.grob.list,'data',data)

function columns2table(P)

j = 0;
icol = ones(1,P.nlist);
npercol = fn_map(@(x)size(x,1),P.columns);
P.indices = zeros(0,P.nlist);
P.valid = zeros(0,1);
while any(icol<=npercol)
    j = j+1;
    k = zeros(1,P.nlist);
    v = -ones(1,P.nlist);
    for i=1:P.nlist
        if icol(i)<=npercol(i)
            k(i) = P.columns{i}(icol(i),1);
            v(i) = P.columns{i}(icol(i),2);
        end
    end
    if any(v==0)
        % some invalid items
        P.valid(j) = 0;
        idx = (v==0);
        P.indices(j,idx) = k(idx);
        icol(idx) = icol(idx)+1;
    else
        % valid items
        if any(v==-1) P.valid(j) = 2; else P.valid(j) = 1; end % beyond the end of some column?
        idx = (v==1);
        P.indices(j,idx) = k(idx);
        icol(idx) = icol(idx)+1;
    end
end

function moveitems(P,flag)

if ~isempty(P.cursel)
    i = P.cursel(:,2)-1;
    if any(diff(i)), return, end
    i = i(1); % which list
    j = P.cursel(:,1); % which rows in the table
    k = P.indices(j,i);
    k = k(k~=0); % which items in the list
    
    icolfirst = find(P.columns{i}(:,1)==k(1),1);
    nitem = length(k);
elseif isfield(P,'curmove')
    % no more selection - use memorized selection
    [i icolfirst nitem] = deal(P.curmove{:});
else
    return
end
    

switch flag
    case 'top'
        icolnew = 1;
    case 'up x10'
        icolnew = max(1,icolfirst-10);
    case 'up'
        icolnew = max(1,icolfirst-1);
    case 'down'
        icolnew = min(P.nperlist(i)-nitem+1,icolfirst+1);
    case 'down x10'
        icolnew = min(P.nperlist(i)-nitem+1,icolfirst+10);
    case 'bottom'
        icolnew = P.nperlist(i);
end

switch flag
    case {'top' 'up x10' 'up'}
        neword = [1:icolnew-1 icolfirst+(0:nitem-1) icolnew:icolfirst-1 icolfirst+nitem:P.nperlist(i)];
    case {'bottom' 'down x10' 'down'}
        neword = [1:icolfirst-1 icolfirst+nitem:icolnew+nitem-1 icolfirst+(0:nitem-1) icolnew+nitem:P.nperlist(i)];
end

P.columns{i} = P.columns{i}(neword,:);
P.curmove = {i icolnew nitem};

% Update table and display
columns2table(P)
displaytable(P)


function changevalid(P)

% Change P.columns
if isempty(P.cursel), return, end
i = P.cursel(:,2)-1;
if any(diff(i)), return, end
i = i(1); % which list
j = P.cursel(:,1); % which rows
k = P.indices(j,i);
k = k(k~=0); % which items in the list
if isempty(k), return, end % blank cell(s) only
icol = find(ismember(P.columns{i}(:,1),k)); % which items in the column
P.columns{i}(icol,2) = ~P.columns{i}(icol(1),2);

% Update table and display
columns2table(P)
displaytable(P)
