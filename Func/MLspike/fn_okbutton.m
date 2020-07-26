function hu=fn_okbutton(varargin)
% function fn_okbutton(varargin)
% function fn_okbutton('wait',varargin)
% function fn_okbutton('closefigure',varargin)
%---
% See also fn_nextbutton

% Thomas Deneux
% Copyright 2009-2017

if nargin>=1
    flag = varargin{1};
    if fn_ismemberstr(flag,{'wait' 'closefigure'})
        varargin(1) = [];
    else
        flag = '';
    end
else
    flag = '';
end

hu = uicontrol('position',[10 10 30 15],'string','ok', ...
    'callback','delete(gcbo)',varargin{:});
switch flag
    case 'wait'
        waitfor(hu)
    case 'closefigure'
        set(hu,'callback','close(gcf)')
    case ''
    otherwise
        error('unknown flag ''%s''',flag)
end
if nargout==0, clear hu, end