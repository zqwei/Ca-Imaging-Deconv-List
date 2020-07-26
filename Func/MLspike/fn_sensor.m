classdef fn_sensor < fn_uicontrol
    % function S = fn_sensor(propname1,propvalue1,...)
    %---
    % creates a 'sensor' control, object optimally designed for controlling
    % the clipping range of an image
    % to manually change the clipping value, click on the control and move
    % the pointer while keeping the button pressed; there are 3 different
    % ways of controling the change depending on which button was pressed:
    % - left button     move horizontally to change contrast, and
    %                   vertically to change luminosity
    % - middle button   move horizontally to change the minimum of the
    %                   clipping range, and vertically to change the
    %                   maximum
    % - right button    changes the contrast, but not the mean value of the
    %                   clipping range
    %
    % See also fn_uicontrol, fn_clipcontrol
    
    % Thomas Deneux
    % Copyright 2008-2017
    
    properties
        mode = 'clip'; % only available mode now
        format = '%.2g';
    end
    
    % Constructor
    methods
        function S = fn_sensor(varargin)
            S = S@fn_uicontrol(varargin{:});
            set(S.hu,'style','edit', ...
                'horizontalalignment','center','fontsize',8, ...
                'value',[0 1], ...
                'backgroundcolor',[.695 .3 .475], ...
                'enable','inactive','buttondownfcn',@(u,evnt)sense(S))
            displayvalue(S)
            
            % listeners: annoying that i have to do like this to detect
            % changes in the superclass properties...
            addlistener(S,'value','PostSet',@(u,e)displayvalue(S));
            
            % set additional properties
            if nargin>0, set(S,varargin{:}), end
        end
    end
    
    % Set/Get
    methods
        function set.mode(S,str)
            if ~fn_ismemberstr(str,{'clip'})
                error('unknown mode ''%s''',str)
            end
            S.mode = str;
        end
    end
    
    % Routines
    methods
        function displayvalue(S,flag)
            if nargin<2, flag = 'minmax'; end
            val = S.value;
            switch S.mode
                case 'clip'
                    switch flag
                        case 'minmax'
                            str = ['min:' num2str(val(1),S.format) ...
                                ' max:' num2str(val(2),S.format)];
                        case 'lumcon'
                            str = ['c:' num2str(mean(val),S.format) ...
                                ' r:' num2str(diff(val),S.format)];
                        case 'luminosity'
                            str = ['center:' num2str(mean(val),S.format)];
                        case 'contrast'
                            str = ['range:' num2str(diff(val),S.format)];
                    end
            end
            set(S.hu,'string',str)
        end
        function sense(S)
            p0 = get(S.hf,'currentpoint'); p0 = p0(1,1:2);
            val0 = S.value;
            switch S.mode
                case 'clip'
                    flag = fn_switch(get(S.hf,'selectiontype'), ...
                        'normal',   'minmax', ...
                        'extend',   'lumcon', ...
                        'alt',      'contrast', ...
                        'open',     'special');
            end
            if strcmp(flag,'special')  
                % center on closest integer
                S.value = val0 - mean(val0);
            else
                displayvalue(S,flag)
                setappdata(S.hf,'previouspoint',p0)
                fn_buttonmotion(@()move(S,val0,p0,flag),S.hf)
            end
            displayvalue(S)
        end
        function move(S,val0,p0,flag)
            pprev = getappdata(S.hf,'previouspoint');
            valprev = S.value;
            p = get(S.hf,'currentpoint');
            setappdata(S.hf,'previouspoint',p)
            dp = p(1,1:2)-p0;
            switch S.mode
                case 'clip'
                    range0 = diff(val0);
                    switch flag
                        case 'minmax'
                            % 50 pixels to span range
                            val = val0 + dp*(range0/50);
                        case 'luminosity'
                            % 50 pixels to span range
                            val = val0 - (dp(1)+dp(2))*(range0/50);
                        case 'contrast'
                            % 100 pixels to increase/decrease range by 10  
                            c = mean(val0);
                            range = range0 * 10^(-(dp(1)+dp(2))/50);
                            val = c + [-range range];
                        case 'lumcon'
                            % the best! contrast is adjusted as above, but
                            % the speed of luminosity change depends on
                            % current range
                            rangeprev = diff(valprev);
                            c = mean(valprev) - (p(2)-pprev(2))*(rangeprev/50);
                            range = range0 * 10^(-dp(1)/50);
                            val = c + [-range/2 range/2];
                    end
                    if diff(val)<=0
                        val = mean(val)+[-10 10]*eps(max(abs(val))); 
                    end
            end
            set(S.hu,'value',val)
            displayvalue(S,flag)
            execcallback(S)
        end
    end
end