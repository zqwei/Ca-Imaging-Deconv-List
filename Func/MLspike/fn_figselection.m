function [subframe hdeco] = fn_figselection(hf)
% function [subframe hdeco] = fn_figselection([hf])
%---
% Select a rectangle area inside a figure

% Thomas Deneux
% Copyright 2015-2017

% Input
if nargin==0, hf = gcf; end

% Save current properties
curfig = fn_get(hf, ...
    {'pointer','userdata','windowbuttondownfcn','windowbuttonmotionfcn','windowbuttonupfcn'}, ...
    'struct');
hc = findall(hf);
curfun = fn_get(hc,'buttondownfcn','struct');

% Prepare variables
corners = zeros(2,2);
hdeco = zeros(1,4);

% Selection
set(hf,'pointer','fullcrosshair','userdata',0, ...
    'windowbuttondownfcn',@(h,e)firstpress)
fn_set(hc,'buttondownfcn','')
waitfor(hf,'userdata',1)

% Restore properties
fn_set(hf,curfig)
fn_set(hc,curfun)

% Coordinates of sub-frame
subframe = [min(corners) abs(diff(corners))];

% Keep frame display or delete it?
if nargout<2
    delete(hdeco), drawnow
end

    function firstpress
        corners(1,:) = get(hf,'currentPoint');
        for k=1:4
            hdeco(k) = uicontrol('parent',hf,'style','frame','foregroundcolor','r', ...
                'units','pixel','pos',[corners(1,:) 1 1]);
        end
        set(hf,'windowbuttondownfcn','', ...
            'windowbuttonmotionfcn',@(h,e)moveframe, ...
            'windowbuttonupfcn',@(h,e)finish)
    end
    function moveframe
        corners(2,:) = get(hf,'currentpoint');
        x1 = min(corners(:,1)); y1 = min(corners(:,2));
        x2 = max(corners(:,1)); y2 = max(corners(:,2));
        w = max(1,x2-x1); h = max(1,y2-y1);
        set(hdeco(1),'pos',[x1 y1 w 1])
        set(hdeco(2),'pos',[x1 y1 1 h])
        set(hdeco(3),'pos',[x1 y2 w 1])
        set(hdeco(4),'pos',[x2 y1 1 h])
    end
    function finish
        moveframe
        set(hf,'userdata',1)
    end


end
