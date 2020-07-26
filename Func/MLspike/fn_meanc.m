function fn_meanc(x,dim,alpha)
% function [m, lb, ub] = fn_meanc(x[,dim[,alpha]])
%---
% same as mean, but also returns a alpha level confidence interval for the mean
% default dim is 1, default alpha is 90%
%---
% si mu vraie moyenne, m moyenne estim�e, s variance estim�e (sans biais)
% alors (m-mu)*sqrt(n)/s ~ Student(n-1)

% Thomas Deneux
% Copyright 2004-2017

if nargin<1, help fn_meanc, return, end

if nargin<2, dim=1; end
if nargin<3, alpha=0.9; end

tflag = (size(x,1)==1);
if (tflag), x=x'; end
n = size(x,1);

if n==0
    m=NaN; lb=NaN; ub=NaN;
    return
end

m = mean(x,dim);
s = std(x,0,dim);

deltastudentnormal = tinv(1-(1-alpha)/2,n-1);
delta = deltastudentnormal*s/sqrt(n);
% delta = s;
lb = m-delta;
ub = m+delta;


