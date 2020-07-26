function p = fn_bootstrap(a,b,varargin)
% function p = fn_bootstrap(a,b[,mode][,'tail','left|right|both'][,'nperm',npermmax])
%---
% Bootstrap test of the equality between the mean (or median) of two
% empirical distributions (by permuting the distribution assignments), 
% or simpler test that a distribution is symmetric over zero (by randomly
% altering the sign of samples and checking either the mean or the median)
%
% Input:
% - a, b    vectors or array (repeat comparisons accross columns) -
%           distributions to be compared (leave b empty for single
%           distribution)
% - mode    'mean' (default) or 'median'
% - tail    'both' (default), 'left' or 'right'
% - npermmax    maximum number of permutation [default: 2e5]
%
% This syntax is not definitive!!!

% Thomas Deneux
% Copyright 2015-2017

% Input
if nargin<2
    nx = 1;
    a = a(:); b = [];
elseif isvector(a) && isvector(b)
    nx = 1;
    a = a(:); b = b(:);
else
    nx = size(a,2);
    if ~isempty(b) && size(b,2)~=nx, error 'x and y must have same number of columns (repetitions of the test)', end
end
docompare = ~isempty(b); % compare two distributions (otherwise test whether single distribution mean/median is zero)
if docompare, data = [a; b]; else data = a; end
na = size(a,1); nb = size(b,1);
if any(isnan(a(:))) || any(isnan(b(:))), error 'NaNs are not handled yet', end
fun = @mean; tail = 'both'; npermmax = 2e5;
i = 0;
while i<length(varargin)
    i = i+1;
    arg = varargin{i};
    if isa(arg,'function_handle')
        fun = arg;
    else
        switch arg
            case 'tail'
                i = i+1; 
                tail = varargin{i};
            case {'nperm' 'npermmax'}
                i = i+1; 
                npermmax = varargin{i};
            case {'mean' 'median'}
                fun = str2func(arg);
            otherwise
                error argument
        end
    end
end

% statistic = difference between fun evaluation over both sets
if docompare
    stat0 = fun(a,1) - fun(b,1);
else
    stat0 = fun(a,1);
end

% prepare vector of p-values
p = zeros(1,nx);
idxx = 1:nx;

% statistics for shuffled data
doabove = ~strcmp(tail,'left');
if doabove
    nabove = zeros(1,nx); % number of times the statistic for shuffled data was above that for real data
end
dobelow = ~strcmp(tail,'right');
if dobelow
    nbelow = zeros(1,nx); % number of times the statistic for shuffled data was below that for real data
end
rng(0,'twister') % make results repeatable

checkups = 10.^(2:floor(log10(npermmax)));
if checkups(end)<npermmax, checkups(end+1) = npermmax; end
curcheck = checkups(1);
% curstep = curcheck/100;
% fn_progress(['computing ' num2str(nx) ' p-values, permutation'],curcheck)
fprintf('computing %i p-values with %i permutations\n',length(idxx),curcheck)
nperm = 0;
while nperm<checkups(end)
    nperm = nperm+1;
    %if ~mod(nperm,curstep), fn_progress(nperm), end
    if docompare
        data1 = data(randperm(na+nb),:);
        stat = fun(data1(1:na,:),1) - fun(data1(na+(1:nb),:),1);
    else
        sub = (rand(1,na)<.5);
        data1 = data; data1(sub,:) = -data(sub,:);
        stat = fun(data1);
    end
    if doabove, nabove = nabove + (stat>=stat0); end
    if dobelow, nbelow = nbelow + (stat<=stat0); end
    if any(nperm==checkups)
        switch tail
            case 'right'
                done = (nabove>20); % we can stop for these elements
                p(idxx(done)) = nabove(done)/nperm;
            case 'left'
                done = (nbelow>20); % we can stop for these elements
                p(idxx(done)) = nbelow(done)/nperm;
            case 'both'
                done = (nabove>10) && (nbelow>10); % we can stop for these elements
                p(idxx(done)) = 2*min(nabove(done),nbelow(done))/nperm;
        end
        fprintf('\b -> %.1f%% of p-values are below %g\n',sum(~done)/nx*100,20/nperm)
        if all(done), break, end
        idxx = idxx(~done);
        stat0 = stat0(~done);
        nabove = nabove(~done);
        data = data(:,~done);
        if nperm<checkups(end)
            curcheck = checkups(find(nperm==checkups)+1);
            %             curstep = curcheck/100;
            %             fn_progress(['computing ' num2str(length(idxx)) ' p-values, permutation'],curcheck)
            fprintf('computing %i p-values with %i permutations\n',length(idxx),curcheck)
        end
    end
end
if ~all(done)
    switch tail
        case 'right'
            p(idxx) = nabove/nperm;
        case 'left'
            p(idxx) = nbelow/nperm;
        case 'both'
            p(idxx) = 2*min(nabove,nbelow)/nperm;
    end
end
