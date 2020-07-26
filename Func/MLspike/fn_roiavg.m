function y = fn_roiavg(x,ind)
% function y = fn_roiavg(x,mask|ind|':')
%---
% Compute average signal from a region of interest.
%
% Input:
% - x       ND array (N>=2) - first 2 dimensions represent space
% - ind     data indices of the pixels belonging to the ROI
%
% Output:
% - y       (N-2)D array - average of x for the pixels inside the ROI
%
% See also fn_maskavg

% Thomas Deneux
% Copyright 2015-2017

s = size(x); if length(s)<3, s(3)=1; end
x = reshape(x,[s(1)*s(2) s(3:end)]);

if strcmp(ind,':')
    y = reshape(mean(x,1),s(3:end));
else
    y = reshape(mean(x(ind,:),1),s(3:end));
end
