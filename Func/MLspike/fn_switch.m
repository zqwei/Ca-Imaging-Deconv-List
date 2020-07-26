function y = fn_switch(varargin)
% function y = fn_switch(x,y_true,[x2,y_true2,[...]]y_false)
% function y = fn_switch(x,case1,y1,case2,y2,..,casen,yn[,ydefault])
% function y = fn_switch(true|false|'on'|'off')
% function y = fn_switch(true|false|'on'|'off','logical'|'on/off')
% function y = fn_switch('on|off','toggle')
% function y = fn_switch(y,y_defaultifempty)
%---
% The 2 first cases are general prototypes: the functions recognize which
% to use according to whether x is logical and scalar
% MAKE SURE THAT X IS SCALAR AND LOGICAL IF YOU WANT TO USE THE FIRST FORM!
% 'case1', 'case2', etc.. can be any Matlab variable to which x is compared
% but if they are cell arrays, x is compared to each of their elements.
%
% The other cases are specialized shortcuts dedicated (except the last one)
% to conversions between logical values and the strings 'on' or 'off'.
%
% See also fn_cast

% Thomas Deneux
% Copyright 2005-2017


x = varargin{1};

if nargin<=2
    
    % specialized functions
    if nargin==1
        % logical <-> on/off conversions
        if ischar(x)
            % on/off -> true/false
            switch x
                case 'on'
                    y = true;
                case 'off'
                    y = false;
                otherwise
                    error 'first input expected to be ''on'' or ''off'''
            end
        else
            % true/false -> on/off
            if x
                y = 'on';
            else
                y = 'off';
            end
        end
    elseif ischar(varargin{2}) && strcmp(varargin{2},'logical')
        % on/off -> true/false conversion only
        if ischar(x)
            switch x
                case 'on'
                    y = true;
                case 'off'
                    y = false;
                otherwise
                    error 'first input expected to be ''on'' or ''off'''
            end
        else
            y = logical(x);
        end
    elseif ischar(varargin{2}) && strcmp(varargin{2},'on/off')
        % true/false -> on/off conversion only
        if ischar(x)
            switch x
                case {'on' 'off'}
                    y = x;
                otherwise
                    error 'first input expected to be ''on'' or ''off'''
            end
        else
            if x
                y = 'on';
            else
                y = 'off';
            end
        end
    elseif ischar(varargin{2}) && strcmp(varargin{2},'toggle')
        % on/off switch
        switch x
            case 'on'
                y = 'off';
            case 'off'
                y = 'on';
            otherwise
                error 'first input expected to be ''on'' or ''off'''
        end
        return
    else
        % return first value, or second if first is empty
        if ~isempty(x)
            y = x;
        else
            y = varargin{2};
        end
    end

elseif (isscalar(x) && islogical(x)) || (nargin==3)     
    
    % "IF"
    karg = 2;
    while true
        if ~isempty(x) && all(x(:)) && all(~isnan(x(:)))
            y = varargin{karg};
            return
        elseif nargin<=karg+1
            y = varargin{karg+1};
            return
        else
            % new test
            x = varargin{karg+1};
            karg = karg+2;
        end
    end
    
else
    
    % "SWITCH"
    ncase = floor((length(varargin)-1)/2);
    for k=1:ncase
        casek = varargin{2*k};
        if iscell(casek) || (~ischar(casek) && ~isscalar(casek) && isscalar(x))
            b = ismember(x,casek); 
        else
            b = isequal(x,casek); 
        end
        if b
            y = varargin{2*k+1};
            return
        end
    end
    if length(varargin)==2*ncase+2
        y = varargin{2*ncase+2};
    else
        error('value does not match any case')
    end
    
end
        