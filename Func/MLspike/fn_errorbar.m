function hl = fn_errorbar(varargin)
% function hl = fn_errorbar([x,]y,ey[,flag][,'colors',colors],line options)
% function hl = fn_errorbar([x,]yy[,flag],...)
% function hl = fn_errorbar(x,ex,y,ey,'xerror',...)
% function hl = fn_errorbar(xx,yy,'xerror',...)
%---
% ym and ystd can be vectors or arrays
% if e is not supplied, y and e are obtained as the mean and
% std/sqrt(n) of yy along its last dimension (note that yy can also be a
% cell array, to handle cases where the number of repetitions are not the
% same for different conditions)
%
% flag can be 'lines' [default], 'bar', 'thinbar', 'patch', 'all', 'xerror'

% Thomas Deneux
% Copyright 2006-2017

if nargin==0, help fn_errorbar, return, end

% Input
% (separate data and options)
flag = 'lines'; opt = {}; cols = [];
nnumarg = 0;
i = 0;
while i<nargin
    i = i+1;
    a = varargin{i};
    if ischar(a)
        switch a
            case {'lines' 'bar' 'thinbar' 'patch' 'xerror' 'all'}
                flag = a;
            case 'colors'
                i = i+1;
                cols = varargin{i};
            otherwise
                opt = varargin(i:end);
                break
        end
    elseif (isscalar(a) && i>=2) % isscalar(a) corresponds to the case with flag 'bar', where the bar width is specified
        opt = varargin(i:end);
        break
    else
        nnumarg = nnumarg+1;
    end
end
% (parent axes)
ha = [];
for i=1:length(opt)-1
    if ischar(opt{i}) && strcmp(opt{i},'parent')
        ha = opt{i+1}; break
    end
end
if isempty(ha), ha = gca; end
% (numeric arguments)
x = []; y = []; e = []; ex = [];
switch nnumarg
    case 1
        Y = varargin{1};
        [y e] = meanstd(Y);
    case 2
        if strcmp(flag,'xerror')
            [X Y] = deal(varargin{1:2});
            if ~ismatrix(X) || ~ismatrix(Y), error 'if error on x and y, >2d is not possible', end
            x  = mean(X,2);
            ex = std(X,0,2)/sqrt(size(X,2));
            y  = mean(Y,2);
            e  = std(Y,0,2)/sqrt(size(Y,2));
        elseif ~isvector(varargin{1}) || isvector(varargin{2})
            [y e] = deal(varargin{1:2});
        else
            [x Y] = deal(varargin{1:2});
            [y e] = meanstd(Y);
        end
    case 3
        [x y e] = deal(varargin{1:3});
    case 4
        [x ex y e] = deal(varargin{1:4});
        ex = ex(:);
        if isempty(flag)
            flag = 'xerror';
        elseif ~strcmp(flag,'xerror')
            error argument
        end
    otherwise
        error arguments
end
if isvector(y), y = y(:); e = e(:); end
if isempty(x), x = (1:size(y,1))'; else x = x(:); end

% Prepare for display
[nt n] = size(y);
if isempty(cols), cols = get(ha,'ColorOrder'); end
ncol = size(cols,1);
yb = y-e; yt = y+e;

% Display
switch flag
    case {'bar' 'thinbar'}
        % bar display
        % (first the error lines because they set the axis)
        [nx ny] = size(y);
        ddx = diff(x,2);
        if max(abs(ddx)) > 100*eps, warning('x points not equidistant'); end
        if isscalar(x)
            dx = 0;
        else
            if fn_matlabversion('newgraphics') && ny<=5
                xdensity = ny/(ny+1.5);
            else
                xdensity = .8;
            end
            dx = (x(2)-x(1)) / ny * xdensity;
        end
        xdispatch = dx * (-(ny-1)/2 + (0:ny-1));
        xx = fn_add(x,xdispatch); 
        switch flag
            case 'bar'
                xpattern = [-1 1 NaN 0 0 NaN -1 1 NaN];
                ypattern = [-1 -1 NaN -1 1 NaN 1 1 NaN];
            case 'thinbar'
                xpattern = [0 0 NaN];
                ypattern = [-1 1 NaN];
        end
        npattern = length(xpattern);
        xx = fn_add(xpattern'*(dx*.25),xx(:)');
        yy = fn_add(ypattern'*e(:)',y(:)');
        xx = reshape(xx,[npattern*nx ny]);
        yy = reshape(yy,[npattern*nx ny]);
        hl{2} = plot(xx,yy,'color','k','parent',ha);
        % (second the bars)
        isholdoff = ~strcmp(get(ha,'nextplot'),'add');
        hold(ha,'on')
        if ~mod(length(opt),2), opt = [1 opt]; end % use width parameter = 1 for bar display
        hl{1} = bar(x,y,opt{:});
        if isholdoff, hold(ha,'off'), end
        uistack(hl{2},'top')
        % (final axis adjustment)
        ax = axis(ha);
        if any(y(:)<0), m=ax(3); else m=0; end
        if isholdoff, axis(ha,[x(1)-dx*ny/2 x(end)+dx*ny/2 m ax(4)]), end
    case 'patch'
        % display error as thick bands
        hl = plot(x,[yb yt],'parent',ha); % first set the axis by calling plot
        delete(hl)
        hl = {gobjects(1,n) gobjects(1,n)};
        for k=1:n
            kc = 1+mod(k-1,ncol);
            hl{1}(k) = patch([x(1:nt)' x(nt:-1:1)'],[yb(:,k)' yt(nt:-1:1,k)'], ...
                (1+cols(kc,:))/2, ...
                'parent',ha, ...
                'edgecolor','none'); %,'facealpha',.5);
            fn_set(hl{1}(k),opt{:})
        end
        for k=1:n
            kc = 1+mod(k-1,ncol);
            hl{2}(k) = line(x,y(:,k),'color',cols(kc,:),'parent',ha);
            fn_set(hl{2}(k),opt{:})
        end
    case 'xerror'
        % scatter plot with errors for both x and y
        nx = size(x,1);
        xdata = [x-ex x+ex nan(nx,1) x x nan(nx,1)]';
        ydata = [y y nan(nx,1) y-e y+e nan(nx,1)]';
        hl = zeros(2,nx);
        hl(2,:) = plot(xdata,ydata,'color','b','parent',ha);
        hl(1,:) = line(repmat(x',2,1),repmat(y',2,1),'color','b','parent',ha, ...
            'linestyle','none','marker','.','markersize',16);
    case 'lines'
        % display error with dotted lines
        hl = plot(x,[y yt yb],opt{:});
        % automatic colors and line style
        ncol = size(cols,1);
        for k=1:n
            set(hl(k+[0 n 2*n]),'color',cols(1+mod(k-1,ncol),:))
        end
        set(hl(1:n),'linestyle','-')
        set(hl(n+1:3*n),'linestyle','--')
        % user options
        nopt = length(opt);
        if nopt>=2
            % ignore first optional argument if the total number of arguments is
            % odd
            if mod(nopt,2)
                set(hl,opt{2:nopt})
            else
                set(hl,opt{:})
            end
        end
    case 'all'
        hl = plot(x,Y(:,:));
        sY = size(Y);
        hl = reshape(hl,n,sY(end));
        for k=1:n
            ck = cols(1+mod(k-1,ncol),:);
            set(hl(k,:),'color',(1+ck)/2)
            line(x,y(:,k),'color',ck,'linewidth',2)
        end
end

if nargout==0, clear hl, end    



%---
function [y e] = meanstd(Y)

if iscell(Y)
    n1 = size(Y{1},1);
    n2 = numel(Y);
    y = zeros(n1,n2); e = zeros(n1,n2);
    for i=1:length(Y)
        y(:,i) = nmean(Y{i},2);
        e(:,i) = nste(Y{i},2);
    end
else
    dim = ndims(Y);
    y   = nmean(Y,dim);
    e   = nste(Y,dim);
end


