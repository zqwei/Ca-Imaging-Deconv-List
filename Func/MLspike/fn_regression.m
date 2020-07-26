function [hl cor pvalue] = fn_regression(x,y,varargin)
% function [hl cor pvalue] = fn_regression(x,y[,ha][,options...])
%---
% Performs linear regression between variables x and y, computes
% correlation and p-value
%
% Available options are:
% - 'square'        maintain aspect ratio between x and y coordinates
% - 'showcorr'      display correlation value
% - 'showpvalue'    display p-value
% - 'jitter',jit    apply a small jitter to all points (to avoid points on
%                   top of each other)
% - 'nodisplay'     no display

% Thomas Deneux
% Copyright 2011-2017

% Input
ha = [];
[dosquare showcorr showpvalue nodisplay] = deal(false);
jitter = 0;
lineoptions = {};
k=0;
while k<length(varargin)
    k = k+1;
    a = varargin{k};
    if ishandle(a)
        ha = a;
    elseif ischar(a)
        switch a
            case 'square'
                dosquare = true;
            case 'showcorr'
                showcorr = true;
            case 'showpvalue'
                showpvalue = true;
            case 'jitter'
                jitter = varargin{k+1};
                k=k+1;
            case 'nodisplay'
                nodisplay = true;
            otherwise
                lineoptions = varargin(k:end);
                break
        end
    else
        error argument
    end
end
if isempty(ha), ha = gca; end
x = x(:);
y = y(:);

% Detect NaNs
ok = ~isnan(x) & ~isnan(y);
x = x(ok); y = y(ok); 

% Fit and correlation coefficient
if length(x)>=2
    mdl = LinearModel.fit(x,y);
    coef = mdl.Coefficients.Estimate;
    c = corrcoef(x,y); cor = c(1,2);
else
    coef = [NaN NaN];
    cor = NaN;
end
xx = [min(x); max(x)];
yfit = coef(1) + coef(2)*xx;

% P-value
if length(x)>=3
    pvalue = mdl.coefTest;
else
    pvalue = NaN;
end

% Display
if nodisplay, hl = []; return, end
xdata = x; ydata = y;
if jitter
    s = size(x);
    xdata = x+(rand(s)-.5)*jitter;
    ydata = y+(rand(s)-.5)*jitter;
end
if ~isempty(x)
    hl(1) = plot(xdata,ydata,'+','parent',ha);
    hl(2) = line(xx,yfit,'color','k','linewidth',2,'parent',ha);
else
    hl = [];
end
if ~isempty(lineoptions), fn_set(hl(1),lineoptions{:}), end
if nargout==0, clear hl, end

% Axis
if dosquare
    fn_axis(ha,'image',1.2)
else
    fn_axis(ha,'tight',1.2)
end

% Title: correlation coefficient
if showcorr || showpvalue
    str = {};
    if showcorr && all(~isnan(cor))
        str{end+1} = sprintf('c: %.2f',cor); 
    end
    if showpvalue && ~isnan(pvalue)
        if pvalue>.05
            str{end+1} = 'p>.05';
        else
            str{end+1} = sprintf('p=%.2g',pvalue);
        end
        %         plog = log10(pvalue);
        %         if plog>-1
        %             str{end+1} = 'p>.1';
        %         elseif plog>-2
        %             if pvalue>=.95
        %                 str{end+1} = 'p<.1';
        %             elseif pvalue>=.005
        %                 str{end+1} = ['p=.0' num2str(round(pvalue*100))];
        %             else
        %                 str{end+1} = 'p=.01';
        %             end
        %         elseif plog>-3
        %             str{end+1} = 'p<.01';
        %         else
        %             str{end+1} = ['p<1e' num2str(ceil(plog))];
        %         end
    end
    str = fn_strcat(str,', ');
    ht = text('string',str,'units','normalized','pos',[1 1],'horizontalalignment','right','verticalalignment','top');
    %if ~isempty(lineoptions), fn_set(ht,lineoptions{:}), end
    hl(3) = ht;
end

% output?
if nargout==0
    clear hl
end