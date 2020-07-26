function fn_basevars(varargin)
% function fn_basevars(['get|send',]name1,name2)
%---
% load base workspace in caller workspace or vice-versa (if 'send' flag)
% usefull when debugging a function and trying to use it as a script
% load variables whose name are given as arguments, or the whole base 
% workspace with noargument 
% Performs inverse operation if first argument is numeric

% Thomas Deneux
% Copyright 2005-2017

% get or send?
flag = 'get';
if nargin>0 && ismember(varargin{1},{'get' 'send'})
    flag = varargin{1};
    varargin{1} = [];
end
switch flag
    case 'get'
        from = 'base';
        to = 'caller';
    case 'send'
        from = 'caller';
        to = 'base';
end

% empty variables -> whole workspace
if isempty(varargin)
    varargin = evalin(from,'who');
end

% do the transfer
for i=1:length(varargin)
    name = varargin{i};
    assignin(to,name,evalin(from,name))      
end
    