function hf = fn_figure(name,varargin)
% function hf = fn_figure(name[,w,h][,'noerase'][,'nofocus'][,options...])
%---
% returns a figure handle associated with a unique name: create the figure
% or return an existing figure handle depending on whether a figure with
% this name already exists

% Thomas Deneux
% Copyright 2015-2017

if isnumeric(name)
    if ishandle(name)
        hf = name;
    else
        hf = figure(name);
    end
else
    hf = findall(0,'type','figure','name',name);
    if isempty(hf)
        hf = figure('name',name,'integerhandle','off','numbertitle','off');
    end
end
[doerase dofocus] = deal(true);
i = 0;
while i<length(varargin)
    i = i+1;
    a = varargin{i};
    if isnumeric(a)
        if isscalar(a)
            w = a;
            i = i+1;
            h = varargin{i};
        else
            [w h] = dealc(a);
        end
        fn_setfigsize(hf,w,h)
    else
        switch a
            case 'noerase'
                doerase = false;
            case 'nofocus'
                dofocus = false;
            otherwise
                set(hf,varargin{i:end})
                break
        end
    end
end
if doerase
    delete(get(hf,'children'))
end
if dofocus
    figure(hf)
else
    set(groot,'CurrentFigure',hf)
    
end
if nargout==0
    clear hf
end
