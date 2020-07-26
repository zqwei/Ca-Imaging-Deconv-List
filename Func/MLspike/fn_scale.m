function hx = fn_scale(barsize,label,col)
% function hx = fn_scale(barsize,label[,color])
%---
% Remove ticks from image display and draw a scale bar with the size and
% label as specified
% 
% See also fn_plotscale, fn_nicegraph, fn_labels

% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_scale, return, end
if nargin<3, col='black'; end    

set(gca,'xtick',[],'ytick',[])
delete(findobj(gca,'tag','fn_scale'))

if ~strcmp(get(gca,'DataAspectRatioMode'),'manual'), axis image, end
ax = axis; 

% bar starts at (10,10) right and above bottom-left corner and has length
% 'barize'; the text is 10 pixels above
lineorigin = fn_coordinates('b2a',[15 15]','position');
xdir = 1-2*strcmp(get(gca,'xdir'),'reverse');
lineend = lineorigin + xdir*[barsize 0]';
linepos = [lineorigin lineend];
textpos = mean(linepos,2) + ...
    fn_coordinates('b2a',[0 10]','vector');

hx(1) = line(linepos(1,:),linepos(2,:),'color',col,'linewidth',3, ...
    'tag','fn_scale');
hx(2) = text(textpos(1),textpos(2),label, ...
    'horizontalalignment','center','verticalalignment','middle', ...
    'color',col,'tag','fn_scale');
if nargout==0, clear hx, end
