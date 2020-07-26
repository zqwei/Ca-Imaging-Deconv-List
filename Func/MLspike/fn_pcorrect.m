function pcorr = fn_pcorrect(pvalues,method,varargin)
% function pcorr = fn_pcorrect(pvalues,method[,dim])
% function test = fn_pcorrect(pvalues,method,alpha[,dim])
%---
% Correct p-values for multiple testing
%
% Input
% - pvalues     vector of p-values (entries with NaN are ignored)
% - method      'bonferroni' or 'b'
%               'holm-bonferroni', 'FWER' or 'hb'
%               'benjamini-hochberg', 'FDR' or 'bh'
% - alpha       statistical level for test
% - dim         dimension(s) on which to apply the correction

% Thomas Deneux
% Copyright 2015-2017

% Input
alpha = []; dim = [];
for i=1:length(varargin)
    a = varargin{i};
    if a<1
        alpha = a;
    else
        dim = a;
    end
end

% Correction only along some specific dimension(s)
if ~isvector(pvalues) 
    if isempty(dim)
        error 'if pvalues is not a vector, please specify on which dimension(s) the correction must be applied'
    end
    s = size(pvalues); nd = length(s);
    dimc = setdiff(1:nd,dim);
    pvalues = fn_reshapepermute(pvalues,{dim dimc});
    pcorr = pvalues;
    if isempty(alpha), alpha = {}; else alpha = {alpha}; end
    for i=1:size(pvalues,2)
        pcorr(:,i) = fn_pcorrect(pvalues(:,i),method,alpha{:});
    end
    perm = zeros(1,nd); perm(dim) = 1:length(dim); perm(dimc) = length(dim)+1:nd;
    pcorr = fn_reshapepermute(pcorr,[s(dim) s(dimc)],perm);
    return
end

% NaN values
inan = isnan(pvalues);
if any(inan)
    pcorr = pvalues;
    if isempty(alpha), alpha = {}; else alpha = {alpha}; end
    pcorr(~inan) = fn_pcorrect(pvalues(~inan),method,alpha{:});
    return
end

% Correction
n = length(pvalues);
switch lower(method)
    case {'bonferroni' 'b'}
        pcorr = pvalues*n;
    case {'holm-bonferroni','fwer','hb'}
        [~, ord] = sort(pvalues);
        pcorr = pvalues; pcorr(ord) = pvalues(ord).*(n:-1:1);
        p=0; for i=ord, [p pcorr(i)] = deal(max(p,pcorr(i))); end 
    case {'benjamini-hochberg','fdr','bh'}
        [~, ord] = sort(pvalues); ord = row(ord);
        pcorr = pvalues; pcorr(ord) = row(pvalues(ord)).*(n./(1:n));
        p=0; for i=ord, [p pcorr(i)] = deal(max(p,pcorr(i))); end 
    otherwise
        error('unknown method ''%s''',method)
end
pcorr = min(1,pcorr);

% Hypothesis testing
if ~isempty(alpha)
    alpha = varargin{1};
    test = (pcorr<=alpha);
    pcorr = test;
end

