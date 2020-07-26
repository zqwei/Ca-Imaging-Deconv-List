function [p beta out3] = fn_GLMtest(X,y,h,testflag)
% function [p beta beta0] = fn_GLMtest(X,y,h,'F')
% function [p beta betaproj] = fn_GLMtest(X,y,h,'T')
%---
% 
% Input:
% - X   regressors - nobs x nreg, or (nobs*nrep) x nreg array
%       if empty, the nobs x nobs identity matrix is used
% - y   measure - nobs x nrep array, or (nobs*nrep) vector
%       3D nobs x nrep x ntest array can be used as well and will result in
%       p to be a (ntest) vector and beta to be a ntest x nreg array
% - h   dimensions of the model that are tested [default = (1:nreg)]
%       or, in the case of a T-test, projection to be tested (a vector of
%       length nreg)
% - 'F' or 'T'  indicate whether to perform a F-test [default] or a T-test
%       if a T-test, h must be scalar; use negative value for testing a <0
%       instead of >0

% Thomas Deneux
% Copyright 2015-2017

% input
[nobs nrep ntest] = size(y);
n = nobs*nrep;
y = reshape(y,[n ntest]);
if size(X,1)~=n
    if isempty(X)
        X = repmat(eye(nobs),nrep,1);
    elseif size(X,1)==nobs
        X = repmat(X,nrep,1);
    else
        error 'length of regressors does not match length of data'
    end
end
X = double(X);
nreg = size(X,2);
if nargin<3, h = []; end
if nargin<4
    testflag = 'F';
end

% estimation in the full model
beta = X\y;
y1 = X*beta;
p1 = size(X,2);

% test
switch upper(testflag)
    case 'F'
        % estimation in the null-hypothesis model
        if ~isempty(h)
            X0 = X; X0(:,h) = [];
            beta0 = X0\y;
            out3 = beta0;
            y0 = X0*beta0;
        else
            X0 = [];
            y0 = 0;
        end
        p0 = size(X0,2);

        % F-score
        F = (n-p1)/(p1-p0) * (sum((y1-y0).^2,1)./sum((y-y1).^2,1));
        
        % p-value
        try
            p = fcdf(F,p1-p0,n-p1,'upper');
        catch
            % old Matlab version
            p = 1-fcdf(F,p1-p0,n-p1);
        end
    case 'T'
        % Projection to be tested
        if isscalar(h)
            gamma = zeros(nreg,1);
            gamma(abs(h)) = sign(h);
        elseif isvector(h) && length(h)==nreg
            gamma = column(h);
        else
            error 'projection vector for T-test must be of same length as the number of regressors'
        end

        % Projection
        betaproj = gamma'*beta;
        out3 = betaproj;
        
        % T-score
        T = betaproj*sqrt(n-p1) ./ sqrt(sum((y-y1).^2,1) * (gamma'*(X'*X)^-1*gamma));
        
        % p-value
        p = tcdf(-T,n-p1); %tcdf(T,n-p1,'upper');
        
    otherwise
        error('invalid test flag ''%s''',testflag)
end

