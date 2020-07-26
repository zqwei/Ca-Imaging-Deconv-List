function x = fn_input(varargin)
% function x = fn_input([name][,defaultval][,min,max])
% function x = fn_input([name][,defaultval][,spec])
%---
% this is a small wrapper for function fn_structedit, to prompt user for
% a single value; normally if defaultval, min and max are integers, x will
% also be integer
%
% fn_input('text') is ambiguous and will result in a numeric output
% use fn_input('name','text') for a string output (with 'text' as default)
% fn_input('text','char') is also ambiguous and will result in an empty
% default
% use fn_input('name','text','char') to have 'text' as string default
% 
% See also fn_structedit, fn_control, fn_reallydlg

% Thomas Deneux
% Copyright 2007-2017

% input
% (handle the input flexibility)
name = {}; defaultval = {}; % no name, no default value
speckeys = {'logical' 'multcheck' ...
        'char' 'xchar' 'double' 'xdouble' 'single' 'xsingle' ...
        'slider' 'xslider' 'logslider' 'xlogslider' 'loglogslider' 'xloglogslider' ...
        'stepper' 'xstepper' 'clip' 'xclip' 'color' 'xcolor' ...
        'file' 'xfile' 'dir' 'xdir'};
if nargin==0
    % no name, no default
else
    a = varargin{1};
    if isnumeric(a) && (nargin==2 && isnumeric(varargin{2}))
        % this is a min/max specification (no name, no default)
    elseif isnumeric(a) || islogical(a)
        % this is a default numerical value (no name)
        defaultval = a;
    elseif iscell(a)
        % this is a specification (no name, no default)
    elseif ~ischar(a)
        error 'first argument should be numeric, logical, char or cell array'
    elseif nargin==1
        if fn_ismemberstr(fn_regexptokens(a,'^([^ ]*)'),speckeys)
            % this is a specification (no name, no default)
        else
            % this is a name
            name = a;
        end
    else
        % first argument is a name, we need to check what are the following
        % arguments
        name = a;
        b = varargin{2};
        if nargin==2
            if iscell(b)
                % this is a spec (no default)
            elseif isnumeric(b)
                % this is a default value
                defaultval = b;
            elseif ~ischar(b)
                error 'argument'
            elseif fn_ismemberstr(fn_regexptokens(b,'^([^ ]*)'),speckeys)
                % this is a spec
            else
                % this is a default value
                defaultval = b;
            end
        elseif nargin==3 && isnumeric(b) && isnumeric(varargin{3})
            % this is a min/max specification (no default)
        else
            % this is a default value
            defaultval = b;
        end
    end
end
   
% specification
kspec = 1+~isequal(name,{})+~isequal(defaultval,{});
spec = varargin(kspec:end);
switch length(spec)
    case 0
        if isempty(defaultval)
            defaultval = 0;
            spec = 'double';
        else
            spec = class(defaultval);
        end
    case 1
        spec = spec{1};
    case 2
        [min max] = deal(spec{:});
        if min>0 &&  max/min>100
            % logarithmic scale
            min = log10(min);
            max = log10(max);
            spec = ['logslider ' num2str(min) ' ' num2str(max) ' .1 %.2g'];
        elseif (isempty(defaultval) || ~mod(defaultval,1)) && ~mod(min,1) && ~mod(max,1)
            spec = ['stepper 1 ' num2str(min) ' ' num2str(max)];
        else
            % slider, min, max
            spec = ['slider ' num2str(min) ' ' num2str(max)];
        end
    otherwise
        error argument
end

% name
if isempty(name), name = 'x'; end

% call to fn_structedit
if isempty(defaultval), s = struct; else s = struct('x',defaultval); end
spec = struct('x',{spec name});
s = fn_structedit(s,spec);

% output
if isempty(s), x=[]; else x=s.x; end
            
