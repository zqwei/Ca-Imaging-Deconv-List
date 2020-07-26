%
% randpermLargeK.m
%
%
% ----------------------------
% Output:
%
% version 1.0
%
% -------------------------------------------------------------------------
% Ziqiang Wei
% weiz@janelia.hhmi.org
% 


function randvec = randpermLargeK(n, k)
    
    if k<=n
        randvec  = randperm(n, k);
    else
        large_n  = ceil(k/n) * n;
        randvec  = mod(randperm(large_n, k), n) + 1;
    end
    
end