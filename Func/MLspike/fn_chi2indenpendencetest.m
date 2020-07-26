function p = fn_chi2indenpendencetest(table)
% function p = fn_chi2indenpendencetest(table)
%---
% Input:
% - table   m x n array - there are 2 random variables X and Y, each can
%           take m and n values, respectively; table counts how many
%           observation were made of each pair (i,j)
%
% Output
% - p       p-value for the null hypothesis that X and Y are drawn
%           independently
%           
% Note that the test is valid only if the number of observations is large
% enough.
% See http://stattrek.com/statistics/dictionary.aspx?definition=Chi-square%20test%20for%20independence

% Thomas Deneux
% Copyright 2015-2017

[nx ny] = size(table);

% total number of observations
N = sum(table(:));

% estimated expectations for each variable
ex = sum(table,2)/N;
ey = sum(table,1)/N;

% expectation for the pair if the variables would be independed
exy = ex*ey;

% expected counts for a size-N population if the variables would be independed
expected = exy * N;

% Chi-square statistic
Chi2 = sum( (table(:)-expected(:)).^2 ./ expected(:) );

% number of degrees of freedom
df = (nx-1) * (ny-1);

% p-value (p = chi2pval(Chi2,df), see inside the code of chi2pval!)
p = gammainc(Chi2/2,df/2,'upper');
