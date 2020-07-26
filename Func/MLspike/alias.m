classdef alias
    % function shortcut = alias(cmd[,str])
    % function disp(shortcut)
    % function alias.save
    % function alias.add
    % function alias.load
    %
    % See also <a href="http://blogs.mathworks.com/desktop/2007/03/29/shortcuts-for-commonly-used-code/"> Matlab shortcuts toolbar</a>! 
    
    % Thomas Deneux
    % Copyright 2009-2017

 
    properties
        command
        text
    end
    
    methods
        function A = alias(cmd,str)
            A.command = cmd;
            if nargin>=2, A.text = str; end
        end
        function disp(A)
            disp('alias object, executes the following command when displayed:')
            disp(A.command)
        end
        function display(A)
            if ~isempty(A.text), disp(A.text), end
            evalin('base',A.command)
        end
    end
    
    methods (Static)
        function save(doappend)
            if nargin<2, doappend=false; end
            fmat = [which('alias') 'at'];
            w = evalin('base','whos');
            w = w(strcmp({w.class},'alias'));
            if isempty(w)
                disp('no alias object to save')
            else
                c = [repmat({','''},1,length(w)); {w.name}; repmat({''''},1,length(w))];
                str = [c{:}];
                disp(['saving alias objects found in base workspace: ' str(2:end)])
                if doappend
                    str = ['save(''' fmat '''' str ',''-APPEND'')'];
                else
                    str = ['save(''' fmat '''' str ')'];
                end
                evalin('base',str)
            end
        end
        function add
            alias.save(true)
        end
        function load
           fmat = [which('alias') 'at'];
           if ~exist(fmat,'file')
               disp('cannot load alias objects: file does not exist')
           else
               disp('loading alias objects from file')
               evalin('base',['load(''' fmat ''')'])
           end
        end
    end
    
end