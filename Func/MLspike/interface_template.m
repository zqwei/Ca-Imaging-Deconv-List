classdef interface_template < interface
    % Write some help about your class here
    
    properties
    end
    
    methods
        function X = interface_template
            hf = figure('integerhandle','off');
            defaultoptions = struct;
            X = X@interface(hf,'interface_template',defaultoptions);
            
            % init graphic objects
            init_grob(X)
            interface_end(X)
            
        end
        function init_grob(X)
            g = struct;
            figure(X.hf)
            g.axes = axes;
            X.grob = g;
        end
        function init_menus(X)
            % first menus created by the 'interface' parent class
            init_menus@interface(X)
            % then add custom menus
            m = X.menus.interface;
        end
    end
    
end


