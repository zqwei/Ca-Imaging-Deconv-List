function fn_setfigsize(hf,w,h)
% function fn_setfigsize(hf,w,h)
% function fn_setfigsize(hf,'default')
% function fn_setfigsize(hf)
%---
% use the 3rd syntax to bring back inside the screen a figure that is
% outside

% Thomas Deneux
% Copyright 2011-2017

if nargin==0, help fn_setfigsize, return, end

% Multiple figures
if ~isscalar(hf)
    for k=1:numel(hf), fn_setfigsize(hf(k),w,h), end
    return
end

if nargin<2
    % just translate the figure if necessary
    pos = get(hf,'pos');
    w = pos(3); h = pos(4);
elseif ischar(w)
    % 'default' flag
    if ~strcmp(w,'default'), error argument, end
    def = get(0,'defaultfigureposition');
    w = def(3); h = def(4);
elseif nargin==2
    h = w(2);
    w = w(1);
end

% Screen size
screenpos = get(0,'ScreenSize');
W = screenpos(3); H = screenpos(4);
while W<w || H<h
    disp('Figure cannot be larger than screen! Dividing size by 2.')
    w = round(w/2);
    h = round(h/2);
end

% Position of top-left corner
pos = get(hf,'pos');
if isequal(pos(3:4),[w h]), return, end % already the good dimension
topleft = [pos(1) pos(2)+pos(4)];
topleft = [min(topleft(1),W-w) min(topleft(2),H-70)];

% New position
set(hf,'pos',[topleft(1) topleft(2)-h w h])
