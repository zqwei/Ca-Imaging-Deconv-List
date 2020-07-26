function fn_ticks(varargin)
% function fn_ticks([ha,]xticklabel,yticklabel)
%---
% Shortcut for
% set(gca,'xtick',1:length(xticklabel),'xticklabel',xticklabel, ...
%     'ytick',1:length(yticklabel),'yticklabel',yticklabel)

% Thomas Deneux
% Copyright 2015-2017

% Input
if isscalar(varargin{1}) && ishandle(varargin{1}) && strcmp(get(varargin{1},'type'),'axes')
    ha = varargin{1};
    varargin(1) = [];
else
    ha = gca;
end
xticklabel = varargin{1};
if length(varargin)>=2, yticklabel = varargin{2}; else yticklabel = []; end

if ~isequal(xticklabel,[])
    set(ha,'xtick',1:length(xticklabel),'xticklabel',xticklabel)
end
if ~isequal(yticklabel,[])
    set(ha,'ytick',1:length(yticklabel),'yticklabel',yticklabel)
end
