function fn_sliderenhance(hu,varargin)
% function fn_sliderenhance(sliderhandle)
%---
% allows a slider uicontrol to evaluate its callback during scrolling
% (instead of only at the moment that the mouse if released):
% just call 'fn_sliderenhance(sliderhandle)' once
%
% notes: 
% - the function sets a 'WindowButtonDownFcn' property in the figure, hence
%   it will fail if this property is already set
% - it also sets a 'DeleteFcn' to the slider and will fail if this property
%   is already set
% - the functions needs to be called again each time the uicontrol is
%   resized
%
% See also fn_slider

% Thomas Deneux
% Copyright 2009-2017

if nargin==0, hu=evalin('base','u'); end

hf = get(hu,'parent');

action = get(hf,'windowbuttondownfcn');

if 1 || isempty(action)
    info = struct( ...
        'active',   [], ...
        'slider',   [], ...
        'position', [] ...
        );
elseif iscell(action) && isequal(action{1},@detectsliderpress)
    info = action{2};
else
    error('cannot enhance slider: a ''WindowButtonDownFcn'' property already exists in figure')
end

k = find(info.slider==hu);
if isempty(k)
    k = length(info.slider)+1;
    info.active(end+1) = k;
end
info.slider(k) = hu;
upos = get(hu,'position');
info.position(k,:) = [upos(1:2) upos(1:2)+upos(3:4)];

% set callback in figure to detect scrolling of the slider
set(hf,'windowbuttondownfcn',{@detectsliderpress,info})

% update in the case of resize, and cancel action in the case of deletion
set(hu,'deletefcn',@cancelaction,'enable','off')

%---
function cancelaction(hu,varargin)

hf = get(hu,'parent');
action = get(hf,'windowbuttondownfcn');
info = action{2};
k = action{3};

info.active(info.active==k) = [];

action{2} = info;
set(hf,'windowbuttondownfcn',action);

%---
function detectsliderpress(hf,evnt,info)

p = get(0,'pointerLocation');
fpos = get(hf,'position');
p = p-fpos(1:2);

nactive = length(info.active);
comp = repmat(p,[nactive 2]) - info.position(info.active,:);
disp(comp)

disp hello


