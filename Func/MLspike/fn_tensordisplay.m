function h = fn_tensordisplay(varargin)
% function h = fn_tensordisplay([X,Y,]Txx,Txy,Tyy[,'sigma',sigma][,'sub',sub][,color][,patch options...]])
% function h = fn_tensordisplay([X,Y,]e[,'sigma',sigma][,'sub',sub][,color][,patch options...]])
% sigma1=temporal sigma, sigma2=spatial sigma
% sub1 and sub2: time and space -rate of point-display
% X,Y,Txx,Txy,Tyy

% Thomas Deneux
% Copyright 2006-2017

if isstruct(varargin{1}) || isstruct(varargin{3})
    if isstruct(varargin{1}), nextarg=1; else nextarg=3; end
    e = varargin{nextarg};
    Txx = e.ytyt;
    Txy = -e.ytyx;
    Tyy = e.yxyx;
    if nextarg==1
        [nj ni] = size(Txx); 
        [X Y] = meshgrid(1:ni,1:nj); 
    else 
        [X Y] = deal(varargin{1:2}); 
    end
    nextarg = nextarg+1;
else
    [nj ni] = size(varargin{3});
    if nargin<5 || ischar(varargin{4}) || ischar(varargin{5}) || any(size(varargin{5})~=[nj ni])
        [X Y] = meshgrid(1:ni,1:nj);
        nextarg = 1;
    else
        [X Y] = deal(varargin{1:2});
        nextarg = 3;
    end
    [Txx Txy Tyy] = deal(varargin{nextarg:nextarg+2});
    nextarg = nextarg+3;
end
if any(size(X)==1), [X Y] = meshgrid(X,Y); end
[nj,ni] = size(X);
if any(size(Y)~=[nj ni]) || ...
        any(size(Txx)~=[nj ni]) || any(size(Txy)~=[nj ni]) || any(size(Tyy)~=[nj ni])
    error('Matrices must be same size')
end
% sigma, sub, color
color = 'r';
while nextarg<=nargin
    flag = varargin{nextarg};
    nextarg=nextarg+1; 
    if ~ischar(flag), color = flag; continue, end
    switch lower(flag)
        case 'sigma'
            sigma = varargin{nextarg};
            nextarg = nextarg+1;
            switch length(sigma)
                case 1
                    sigmax = sigma;
                    sigmay = sigma;
                case 2
                    sigmax = sigma(2);
                    sigmay = sigma(1);
                otherwise
                    error('sigma definition should entail two values');
            end
            h = fspecial('gaussian',[2*ceil(sigmay)+1 1],sigmay)*fspecial('gaussian',[1 ceil(2*sigmax)+1],sigmax);
            Txx = imfilter(Txx,h,'replicate');
            Txy = imfilter(Txy,h,'replicate');
            Tyy = imfilter(Tyy,h,'replicate');
        case 'sub'
            sub = varargin{nextarg};
            nextarg = nextarg+1;
            if iscell(sub)
                [x y] = meshgrid(sub{2},sub{1});
                sub = y+nj*(x-1);
            end
            switch length(sub)
                case 1
                    [x y] = meshgrid(1:sub:ni,1:sub:nj);
                    sub = y+nj*(x-1);
                case 2
                    [x y] = meshgrid(1:sub(2):ni,1:sub(1):nj);
                    sub = y+nj*(x-1);
            end
            X = X(sub); Y = Y(sub);
            Txx = Txx(sub); Txy = Txy(sub); Tyy = Tyy(sub);
            [nj ni] = size(sub);
        otherwise
            break
    end    
end
% options
options = {varargin{nextarg:end}};


npoints = 50;
theta = (0:npoints-1)*(2*pi/npoints);
circle = [cos(theta) ; sin(theta)];
Tensor = cat(3,Txx,Txy,Txy,Tyy);        % jdisplay x idisplay x tensor
Tensor = reshape(Tensor,2*nj*ni,2);     % (display x 1tensor) x 2tensor
Ellipse = Tensor * circle;              % (display x uv) x npoints
Ellipse = reshape(Ellipse,nj*ni,2,npoints);         % display x uv x npoints
XX = repmat(X(:),1,npoints);                        % display x npoints
YY = repmat(Y(:),1,npoints);                        % display x npoints
U  = reshape(Ellipse(:,1,:),nj*ni,npoints);         % display x npoints
V  = reshape(Ellipse(:,2,:),nj*ni,npoints);         % display x npoints
umax = max(U')'; vmax = max(V')';
umax(umax==0)=1; vmax(vmax==0)=1;
if ni==1, dx=1; else dx = X(1,2)-X(1,1); end
if nj==1, dy=1; else dy = Y(2,1)-Y(1,1); end
fact = min(dx./umax,dy./vmax)*.35;
fact = repmat(fact,1,npoints);
U = XX + fact.*U;
V = YY + fact.*V;
h = fill(U',V',color,'EdgeColor',color,options{:});

if nargout==0, clear h, end
       