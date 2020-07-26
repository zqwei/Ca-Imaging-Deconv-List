function mask = fn_maskselect(a,mouseflag,dorepeat,cm)
% function mask = fn_maskselect(image[,mouseflag[,dorepeat[,colormap]]])
%---
% ROI selection within an image. Returns an array of logicals. 
%
% Input:
% - image       2D array
% - mouseflag   'rect', 'poly' [default], 'free', 'ellipse'
% - dorepeat    select multiple regions? [default = false]
% - colormap    color map to use for image display
% 
% Output:
% - mask        logical array the same size of image indicating interior of
%               the mask
%
% See also fn_maskavg, fn_imvect

% Thomas Deneux
% Copyright 2011-2017

% Input
[nx ny] = size(a);
if nargin<2, mouseflag = 'poly'; end
if nargin<3, dorepeat = false; end
if nargin<4, cm = []; end
switch mouseflag
    case 'rect'
        mouseflag = 'rectangle';
    case 'ellipse'
        error('not implemented yet')
    case {'poly' 'free'}
        % ok
    otherwise
        error('unknown flag ''%s''',mouseflag)
end
mouseflag= [mouseflag '+'];
    
% prepare display
hf = figure; set(hf,'tag','fn_maskselect','numbertitle','off','name','Please select region')
if ~isempty(cm), colormap(cm), end
imagesc(permute(a,[2 1 3])); axis image
set(gca,'xtick',[],'ytick',[])
if dorepeat
    more = uicontrol('string','more','style','togglebutton', ...
        'pos',[5 5 40 18]);
    uicontrol('string','ok','callback',@(u,e)close(hf), ...
        'pos',[50 5 20 18]);
end

% go (loop if dorepeat is true)
mask = false;
while true
    poly = fn_mouse(mouseflag);
    mask = xor(mask,poly2mask(poly(2,:),poly(1,:),nx,ny));
    if dorepeat
        waitfor(more,'value',1)
        if ~ishandle(more), break, end
        set(more,'value',0)
    else
        close(hf)
        break
    end
end

