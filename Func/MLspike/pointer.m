classdef pointer < handle
    % implements a pointer to any Matlab object; it has three methods
    % p = pointer(x)
    % setvalue(p,x)
    % x = getvalue(p)
    
    % Thomas Deneux
    % Copyright 2007-2017

    properties
        x
    end
    properties (Transient)
        y = struct;
    end
    
    methods
        function p = pointer(x)
            if nargin>0
                p.x = x;
            end
        end
        function setvalue(p,x)
            p.x = x;
        end
        function x = getvalue(p)
            x = p.x;
        end
        function setfield(p,f,y)
            p.x.(f) = y;
        end
        function y = getfield(p,f)
            y = p.x.(f);
        end
        function set.x(p,x)
            if isa(x,'pointer'), error('pointers of pointer are forbidden'), end
            p.x = x;
        end
        function disp(p)
            disp('pointer object with value:')
            disp(p.x)
        end
        function display(p)
            fprintf('\n%s = \n\n',inputname(1))
            disp(p)
        end
    end
end
        