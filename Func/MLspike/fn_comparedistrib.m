function [p hl] = fn_comparedistrib(x,y,method,varargin)
% function [pval hl] = fn_comparedistrib(x,y[,test][,'tail','left|right|both']
%       [,'showmean'][,'ylim',ylim][,'xlabels',xlabels][,'pdisplaymode','ns|p'])
%---
% Perform any of 'ranksum', 'signrank' or 'signtest' test and display the
% data and p-value.
%
% Input
% - x,y     data points; for signrank or signtest, y can be a scalar
%           (the tested median/mean value, typically 0)
% - test    'ranksum' (=default if y is nonscalar)
%           'signrank'
%           'signtest' (=default if y is scalar)
%           'bootstrap' (test on the mean)
%           p - providing a p-value results in skipping the test and
%           displaying thin p-value

% Thomas Deneux
% Copyright 2015-2017

% Input
if nargin<2, y = 0; end
if nargin<3, method = fn_switch(isscalar(y),'signtest','ranksum'); end
i = 0; tail = 'both'; ylim = []; showmean = false; xlabels = {};
pdisplaymode = 'ns';
while i<length(varargin)
    i = i+1;
    switch(varargin{i})
        case 'tail'
            i = i+1;
            tail = varargin{i};
        case 'xlabels'
            i = i+1;
            xlabels = varargin{i};
        case 'ylim'
            i = i+1;
            ylim = varargin{i};
        case 'pdisplaymode'
            i = i+1;
            pdisplaymode = varargin{i};
        case 'showmean'
            showmean = true;
        otherwise
            error('unknown flag ''%s''',varargin{i})
    end
end

% p-value
if all(isnan(x)) || all(isnan(y))
    p = NaN;
elseif isnumeric(method)
    p = method;
else
    switch method
        case {'ranksum' 'signrank' 'signtest'}
            p = feval(method,x,y,'tail',tail);
        case 'bootstrap'
            p = fn_bootstrap(x,y,'mean','tail',tail);
        case 'bootstrapmedian'
            p = fn_bootstrap(x,y,'median','tail',tail);
        case 'bootstrapsign'
            p = fn_bootstrap(x-y,[],'mean','tail',tail);
        case 'bootstrapsignmedian'
            p = fn_bootstrap(x-y,[],'median','tail',tail);
        otherwise
            error('unknown test ''%s''',method);
    end
end

% display
dualdisplay = strcmp(method,'ranksum') || ~isscalar(y);
if dualdisplay
    xlim = [0 3];
    alldata = [row(x) row(y)];
    if strcmp(method,'ranksum')
        xx = [ones(1,length(x)) 2*ones(1,length(y))];
        hl{1} = plot(xx,alldata,'o','color',[1 1 1]*.6); % no connecting lines
    else
        hl{1} = plot(1:2,[row(x); row(y)],'color',[1 1 1]*.6,'marker','o'); % connecting lines
    end
    if showmean
        line(1:2,[nmean(x) nmean(y)],'color','b')
    end
    switch method
        case 'ranksum'
            hl{2}(1) = line(1:2,[nmedian(x) nmedian(y)],'color','k','linestyle','none','marker','*');
            hl{2}(2) = line(1:2,[nmedian(x) nmedian(y)],'color','k','linewidth',2);
        otherwise
            % show individual medians, but also a slope indicating the
            % median difference (which is different from the difference
            % of the medians!)
            hl{2}(1) = line(1:2,[nmedian(x) nmedian(y)],'color','k','marker','*','linestyle','none');
            yl = mean([nmedian(x) nmedian(y)])+[-.5 .5]*nmedian(y-x);
            hl{2}(2) = line(1:2,yl,'color','k','linewidth',2);
    end
    if isempty(ylim)
        if all(isnan(alldata))
            ylim = [0 1];
        else
            m = min(alldata); M = max(alldata);
            ylim = m+[-.1 1.3]*(M-m);
        end
    end
    set(gca,'xlim',xlim,'ylim',ylim)
    fn_markpvalue(1.5,[],p,pdisplaymode)
else
    xlim = [0 2];
    plot(ones(1,length(x)),x,'o','color',[1 1 1]*.6)
    line([.5 1.5],mean(x)*[1 1],'color','k','linewidth',2)
    uistack(line(xlim,[y y],'color','k','linestyle','--'),'bottom')
    if isempty(ylim)
        if all(isnan(x))
            ylim = [0 1];
        else
            m = min(x); M = max(x);
            ylim = m+[-.1 1.3]*(M-m);
        end
    end
    set(gca,'xlim',xlim,'ylim',ylim)
    fn_markpvalue(1,[],p,pdisplaymode)
end
if ~isempty(xlabels)
    set(gca,'xtick',1:length(xlabels),'xticklabel',xlabels,'xTickLabelRotation',30)
end

% output?
if nargout==0
    clear p
end

% immediate display is usefull when multiple comparisons are being computed
drawnow
