function fn_review_showres(x,info)
% function fn_review_showres(x,info)
%---
% this function is the default call by function fn_review
% it can be edited, but always have only one argument
% after finishing using it, please return the code to 'plot(x), axis tight'
%
% See also fn_review

% Thomas Deneux
% Copyright 2005-2017

if ~isnumeric(x) || ~ismatrix(x)
    error 'fn_review can display automatically only 1D and 2D numeric arrays'
end

if isvector(x) || size(x,2)<=min(20,size(x,1)/4)
    plot(squeeze(x),'parent',info.ha)
    axis tight
else
    imagesc(x,'parent',info.ha)
end
        
