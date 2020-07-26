%
% columnVec.m
%
%
% ----------------------------
% Output: a columnized vector
%
% version 1.0
%
% -------------------------------------------------------------------------
% Ziqiang Wei
% weiz@janelia.hhmi.org
% 

function A = columnVec(A)
    if ~iscolumn(A); A = A'; end
end