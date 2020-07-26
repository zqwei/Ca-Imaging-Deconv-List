classdef fn_pointer < dynamicprops & hgsetget
    % function p = fn_pointer('fieldname1',value1,'fieldname2',value2, ...)
    %---
    % An fn_pointer object acts exactly as a structure, except that it is
    % passed has a handle (i.e. different copies of the object point to and
    % modify the same data).
    % fn_pointer is actually a small wrapper for Matlab 'dynamicprops'
    % class
    
    % Thomas Deneux
    % Copyright 2015-2017

    
    methods
        function X = fn_pointer(varargin)
            if nargin==0, return, end
            if nargin>1
                s = struct(varargin{:});
            else
                s = varargin{1};
                if ~isstruct(s)
                    s = struct('x',s);
                elseif ~isscalar(s)
                    error 'only a scalar structure can be converted to a fn_pointer object'
                end
            end
            F = fieldnames(s);
            nf = length(F);
            for k=1:nf
                f = F{k};
                X = subsasgn(X,substruct('.',f),s.(f));
            end 
        end
        function X = subsasgn(X,f,x)
            switch f(1).type
                case '()'
                    if length(f)>1
                        subsassgn(X(f(1).sub{:}),f(2:end),x)
                    else
                        X(f(1).subs{:}) = x;
                    end
                case '.'
                    if strcmp(f(1).subs,'fields')
                        error 'it is not possible to set a property called ''fields'' to an fn_pointer object'
                    end
                    if isa(x,'fn_pointer'), error 'fn_pointer property value cannot be an fn_pointer', end
                    % add dynamic property if necessary, and that's it!
                    donewprop = isempty(findprop(X,f(1).subs));
                    if donewprop
                        P = addprop(X,f(1).subs); 
                        P.SetObservable = true; % make the new property observable
                    end
                    if length(f)>1
                        X.(f(1).subs) = subsasgn(X.(f(1).subs),f(2:end),x);
                    else
                        X.(f(1).subs) = x;
                    end
                otherwise
                    error('wrong referencing of fn_pointer object')
            end
        end
        function b = isfield(X,f)
            b = isprop(X,f);
        end
        function setfield(X,f,x)
            if ~isprop(X,f), addprop(X,f); end
            X.(f) = x;
        end
        function x = getvalue(X)
            if ~isequal(properties(X),{'x'})
                error 'getvalue and setvalue can be used only when fn_pointer object has a unique property ''x'''
            end
            x = X.x;
        end
        function setvalue(X,x)
            if ~isequal(properties(X),{'x'})
                error 'getvalue and setvalue can be used only when fn_pointer object has a unique property ''x'''
            end
            X.x = x;
        end
    end
    
end
