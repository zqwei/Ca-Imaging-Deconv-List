function [s grid] = fn_alignimage(a,b,varargin)
% function [[s grid] =] fn_alignimage(a,b[,shift[,'nouser']]['slider|edit'])
%---
% display a superposition of gray-level images a and b, and allow to move
% image b (includes translation, rotation and rescaling)
% 
% Input:
% - a       reference image
% - b       images for which the transformation with respect to a should be
%           estimated 
% - shift   initialization of the translation part of the transformation
%           [default=[0 0]]
% - 'nouser'    only show the superposition, and return without showing
%           controls that allow user to change the parameters of the
%           transformation 
% - 'slider|edit'   specify the type of controls to use: 'slider' [default]
%           is faster and smoother to use compared to 'edit', but less
%           precise
%
% Output:
% - s       structure with translation, rotation and rescaling parameters
%           note that rotation and rescaling are to be performed centered
%           on the center of the image
% - grid    interpolation grid: to realign b onto a use the command
%           breg = interpn(b,gridb(:,:,1),gridb(:,:,2),'linear',0);
% 
% Example:
%   load trees, 
%   Y = interp2(1:350,(1:258)',X,-4.3:344.7,(13:270)');
%   shift=fn_alignimage(X,Y)

% Thomas Deneux
% Copyright 2011-2017

% Input
a = double(a);
b = double(b);
shift = [0 0]; douser = true; controltype = 'slider';
for i=1:length(varargin)
    arg = varargin{i};
    if isnumeric(arg)
        shift = arg;
    else
        switch(arg)
            case 'nouser'
                douser = false;
            case {'slider' 'edit'}
                controltype = arg;
            otherwise
                error argument
        end
    end
end

% Figure
hf = figure(863);
set(hf,'numbertitle','off','name','fn_alignimage')

% Rescale
a = a-min(a(:)); a = a/max(a(:));
b = b-min(b(:)); b = b/max(b(:)); 

% Prepare affinity
[nxa nya] = size(a);
[nxb nyb] = size(b);
centera = ([nxa; nya]+1)/2;
centerb = ([nxb; nyb]+1)/2;
[xxa yya] = ndgrid(1:nxa,1:nya);
grida = [ones(1,nxa*nya); xxa(:)'; yya(:)'];

% Controls
s = struct( ...
    'xshift',shift(1),'yshift',shift(2), ...
    'scale',1,'angle',0, ...
    'mode','diff', ...
    'clip',[-.5 .5], ...
    'colormap','gray');
if douser
    switch controltype
        case 'slider'
            spec1 = struct( ...
                'xshift',sprintf('slider %i %i .1',-nxa,nxa),'yshift',sprintf('slider %i %i .1',-nya,nya), ...
                'scale','logslider -2 2 .01','angle','slider -2 2 .01');
        case 'edit'
            spec1 = struct( ...
                'xshift','double','yshift','double', ...
                'scale','double','angle','double');
    end
    spec2 = struct( ...
        'mode',{{'diff'}}, ...
        'clip','double', ...
        'colormap',{{'gray' 'jet' 'mapgeog' 'signcheck'}});
    spec = fn_structmerge(spec1,spec2);
    X = fn_control(s,spec,@(x)showimages,'okbutton');
else
    X = s(1);
    X.s = s(1);
end

% Display
clf(hf)
set(hf,'tag','xx','keypressfcn',@(h,e)keypress(e))
fn_scrollwheelregister(hf,@(n)scrollwheel(n))
ha = axes('parent',hf);
hi = imagesc(a','parent',ha);
axis(ha,'image')
set(hi,'buttondownfcn',@(u,e)startmove,'hittest','on')
set(ha,'clim',[-.5 .5],'climmode','manual')
p0 = []; shift0 = [];

% First display
bmov = [];
showimages(true)

if douser
    waitfor(X.hp)
    if ishandle(hf), close(hf), end
else
    drawnow
end

% output?
if nargout==0 && ~douser
    clear s
else
    s = rmfield(s,{'mode' 'clip' 'colormap'});
    grid = interpgrid(s);
    grid = grid(:,:,[2 3]);
end

    function startmove
        p0 = get(ha,'currentPoint'); p0 = p0(1,1:2);
        shift0 = [X.xshift; X.yshift];
        fn_buttonmotion(@moveb,hf)
    end
    function moveb
        p = get(ha,'currentPoint'); p = p(1,1:2);
        shift = shift0 + [p(1)-p0(1); p(2)-p0(2)];
        X.xshift = shift(1); X.yshift = shift(2);
        showimages(true)
    end
    function keypress(e)
        d = [];
        switch e.Key
            case 'downarrow'
                d = [0; 1];
            case 'uparrow'
                d = [0; -1];
            case 'leftarrow'
                d = [-1; 0];
            case 'rightarrow'
                d = [1; 0];
        end
        if isempty(d), return, end
        if ~isempty(e.Modifier)
            switch e.Modifier{1}
                case 'shift'
                    d = d*5;
                case 'control'
                    d = d/10;
            end
        end
        X.xshift = X.xshift + d(1); X.yshift = X.yshift + d(2);
        showimages(true)
    end
    function scrollwheel(n)
        X.scale = X.scale * 10^(-n*.01);
        showimages(true)
    end
    function gridb = interpgrid(s)
        m = s.scale * [cos(s.angle) sin(s.angle); -sin(s.angle) cos(s.angle)];
        M = [1 0 0; centera+[s.xshift; s.yshift]-m*centerb m];
        gridb = permute(reshape(M\grida,[3 nxa nya]),[2 3 1]);
    end
    function showimages(dorecompute)
        % bmov = min(max(fn_translate(b,shift),0),1);
        
        if nargin<1
            dorecompute = any(ismember(X.changedfields,{'xshift' 'yshift' 'scale', 'angle'}));
        end
        
        if dorecompute
            gridb = interpgrid(X);
            bmov = interpn(b,gridb(:,:,2),gridb(:,:,3),'linear',0);
        end
        
        switch(X.mode)
            case 'diff'
                im = a-bmov;
        end
        
        im = fn_clip(im,X.clip,X.colormap);
        set(hi,'cdata',permute(im,[2 1 3]))
        drawnow
        
        s = X.s;
    end

end

