%
% explainedPCA.m
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

function perEV        = explainedPCA(nSessionData, timeMarker, params)

    [numTrial, numUnits, numT] = size(nSessionData);
    
    switch upper(timeMarker)
        case 'CONSTANT'
            coeff        = pca(reshape(permute(nSessionData, [1 3 2]), numTrial*numT, numUnits));
            perEV        = arrayfun(@(tIndex) EVperTime(nSessionData(:,:,tIndex), coeff),....
                                        1:numT, 'UniformOutput', false);
        case 'TIME_VARYING'
            perEV        = arrayfun(@(tIndex) EVperTime(nSessionData(:,:,tIndex),...
                                        pca(squeeze(nSessionData(:,:,tIndex)))),....
                                        1:numT, 'UniformOutput', false);
            
        case 'STAGE_VARYING'
            timePoints      = timePointTrialPeriod(params.polein, params.poleout, params.timeSeries);
            perEV           = cell(numT,1);
            for nPeriod     = 1:length(timePoints) - 1
                nPeriodData = nSessionData(:,:,timePoints(nPeriod):timePoints(nPeriod+1));
                nT          = timePoints(nPeriod+1)-timePoints(nPeriod) + 1;
                coeff       = pca(reshape(permute(nPeriodData, [1 3 2]), numTrial*nT, numUnits));
                perEV(timePoints(nPeriod):timePoints(nPeriod+1))  = arrayfun(@(tIndex) EVperTime(nPeriodData(:,:,tIndex), coeff),....
                                                                    1:nT, 'UniformOutput', false);
            end
    end
    
    perEV = cell2mat(perEV);
end

function perEVperTime = EVperTime(nData, coeff)
    if ndims(nData)   == 3
        nData         = squeeze(nData);
    end    
    perEVperTime      = var(nData*coeff)/ trace(cov(nData));
    perEVperTime      = perEVperTime(1);
    
end
