function varargout = dichotomy(fun,varargin)
% function [x out1 out2 ...] = dichotomy(fun,lb,ub,tolx,xstart)
% function [x out1 out2 ...] = dichotomy(fun,lb2ub,tolx)

% Thomas Deneux
% Copyright 2015-2017

if nargout==0, help dichotomy, return, end

% Input
doout = (nargout>=2);
if isscalar(varargin{1})
    [lb ub tolx] = deal(varargin{1:3});
    usexstart = (nargin>=5);
    if usexstart, xstart = varargin{4}; end
    lb2ub = [];
else
    [lb2ub tolx] = deal(varargin{:});
    if ~isvector(lb2ub) || length(lb2ub)<=3, error argument, end
    usexstart = false;
end

if isempty(lb2ub)
    % Build the search triplet
    searchbounds = [lb ub];
    searchtriplet = searchbounds([1 1 2]);
    if doout
        out = cell(1,nargout-1);
        out1 = cell(1,nargout-1);
        out2 = cell(1,nargout-1);
        [e1 out1{:}] = fun(lb);
        [e2 out2{:}] = fun(ub);
        e3 = [e1 e1 e2];
        out3 = [out1; out1; out2];
    else
        e1 = fun(lb);
        e2 = fun(ub);
        e3 = [e1 e1 e2];
    end
else
    % Special, test a series of points before running the dichotomy
    ntest = length(lb2ub);
    e = zeros(1,ntest);
    if doout
        out = cell(ntest,nargout-1);
        for i=1:ntest, [e(i) out{i,:}] = fun(lb2ub(i)); end
    else
        for i=1:ntest, e(i) = fun(lb2ub(i)); end
    end
    [dum imin] = min(e);
    itriplet = max(1,min(ntest,imin-1:imin+1));
    searchtriplet = lb2ub(itriplet);
    e3 = e(itriplet);
    if doout, out3 = out(itriplet,:); end
end

% search loop
while searchtriplet(3)-searchtriplet(1)>tolx && any(diff(e3))
    
    % choose new test value
    if usexstart
        testval = xstart;
        side = fn_switch(xstart>searchtriplet(2),'right','left');
        usexstart = false;
    else
        side = fn_switch(diff(searchtriplet,2)<0,'left','right');
        testval = mean(searchtriplet(fn_switch(side,'left',1:2,'right',2:3)));
    end
    
    % evaluate energy function
    if doout
        [e out{:}] = fun(testval);
    else
        e = fun(testval);
    end
    
    % update search triplet
    switch side
        case 'left'
            if e<e3(2)
                searchtriplet = [searchtriplet(1) testval searchtriplet(2)];
                e3 = [e3(1) e e3(2)];
                if doout, out3 = [out3(1,:); out; out3(2,:)]; end
            else
                if e>e3(1), disp 'non convex function!!', end
                searchtriplet = [testval searchtriplet(2:3)];
                e3 = [e e3(2:3)];
                if doout, out3 = [out; out3(2:3,:)]; end
            end
        case 'right'
            if e<e3(2)
                searchtriplet = [searchtriplet(2) testval searchtriplet(3)];
                e3 = [e3(2) e e3(3)];
                if doout, out3 = [out3(2,:); out; out3(3,:)]; end
            else
                if e>e3(3), disp 'non convex function!!', end                
                searchtriplet = [searchtriplet(1:2) testval];
                e3 = [e3(1:2) e];
                if doout, out3 = [out3(1:2,:); out]; end
            end
    end
end

if doout
    varargout = [searchtriplet(2) out3(2,:)];
else
    varargout = {searchtriplet(2)};
end
