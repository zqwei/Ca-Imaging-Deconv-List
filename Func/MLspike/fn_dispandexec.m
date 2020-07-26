function fn_dispandexec(varargin)
% function fn_dispandexec(cmd1,cmd2,...)
% function fn_dispandexec(fun,arg1,arg2,...)
%--
% display and execute commands or functions

% Thomas Deneux
% Copyright 2011-2017

if nargin==0, help fn_dispandexec, return, end

if isscalar(varargin) && iscell(varargin{1}), varargin = varargin{1}; end
switch class(varargin{1})
    case 'char'
        for k=1:length(varargin)
            cmd = varargin{k};
            disp(cmd)
            evalin('base',cmd)
        end
    case 'function_handle'
        fun = varargin{1};
        disp(char(fun))
        feval(fun,varargin{2:end})
    otherwise
        error('first argument must be a string or a function handle')
end

