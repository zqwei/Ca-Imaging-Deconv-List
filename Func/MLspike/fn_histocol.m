function fn_histocol(x,xrange,cidx,varargin)
% function fn_histocol(x,xbinwidth|xbinedges,cidx[,cmap][,'indiv'][,ha])
% function fn_histocol(x,xbinwidth|xbinedges,pvalues[,'indiv'][,ha])
%---
% Draw a histogram of x values with bins of width xwidth, and color each
% element according to the provided color indices cidx and color map cmap.
% 
% When only 3 arguments are used and 3rd argument has real values between 0
% and 1, they are considered as p-values, and a default colormap is used
% for them.

% Thomas Deneux
% Copyright 2015-2017

% Input
ok = ~isnan(x) & ~isnan(cidx);
x = x(ok);
cidx = cidx(ok);
if ~isempty(varargin) && ~ischar(varargin{1})
    cmap = varargin{1};
    varargin(1) = [];
elseif ~any(mod(cidx,1)) && all(cidx>0)
    % cidx are indeed color indices, use the current colormap
    cmap = colormap;
    cmap = interp1(linspace(0,1,size(cmap,1)),cmap,linspace(0,1,max(cidx)));
elseif all(cidx>=0 & cidx<=1)
    % these look like p-values
    pval = cidx;
    cidx = 1+(pval<=.05)+(pval<=.01)+(pval<=.001)+(pval<=.0001);
    cmap = [1 0 0; 1 .65 0; 1 1 0; 0 .75 0; .4 .4 1];
else
    error 'third argument is not likely to be color indices, nor p-values'S
end
ncol = size(cmap,1);
doindiv = false; ha = [];
for i=1:length(varargin)
    a = varargin{i};
    if ischar(a)
        if strcmp(a,'indiv')
            doindiv = true;
        else
            error argument
        end
    elseif ishandle(a) && strcmp(get(a,'type'),'axes')
        ha = a;
    end
end
if isempty(ha), ha = gca; end

% Make histograms
if isscalar(xrange)
    xstep = xrange;
    x1 = floor(x/xstep);    
    xedges = (min(x1):max(x1)+1)*xstep;
    x1 = x1-min(x1)+1;
else
    xedges = xrange;
    x1 = sum(bsxfun(@ge,column(x),row(xedges)),2);
    outside = (x1==0) | (x1==length(xedges));
    x(outside) = []; x1(outside) = []; cidx(outside) = [];
end
nbin = length(xedges)-1;

% Display
if ~strcmp(get(gca,'NextPlot'),'add'), cla, end
for i=1:nbin
    cidxi = cidx(x1==i);
    if doindiv
        % display individual data points as a small rectangle
        cidxi = sort(cidxi);
        for j=1:length(cidxi)
            rectangle('position',[xedges(i) j-1 diff(xedges(i:i+1)) 1],'facecolor',cmap(cidxi(j),:),'parent',ha)
        end
    else
        yi = 0;
        for j=1:ncol
            nij = sum(cidxi==j);
            %N(i,j) = nij;
            if nij==0, continue, end
            rectangle('position',[xedges(i) yi diff(xedges(i:i+1)) nij],'facecolor',cmap(j,:),'parent',ha)
            yi = yi+nij;
        end
    end
end
set(gca,'xlim',xedges([1 end]))
%if ~doinv, disp(N), end
