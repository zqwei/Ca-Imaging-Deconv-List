% generate nonhomogeneous spikes from expected spiking rate (time series)

function [spkTime, spkCounts] = NHpoisson(rate, timeBins, binSize, numTrial)
    % algorithm from http://transp-or.epfl.ch/courses/OptSim2012/slides/05b-poisson.pdf
    dt         = 0.001; % sampling rate = 1000 Hz
    t_start    = timeBins(1);
    t_end      = timeBins(end);
    maxRate    = max(rate);
    spkTime    = cell(numTrial, 1);
    spkCounts  = zeros(numTrial, length(timeBins));
    for nTrial = 1:numTrial
        kSpk     = 0;
        while kSpk == 0
            t        = t_start;
            kSpk     = 0;
            spkTrial = nan(ceil((t_end-t_start)/dt), 1);
            while t<=t_end
                r    = rand();
                t    = t - log(r)/maxRate;
                s    = rand();
                lambda_t = rate(sum(t>timeBins));
                if s<= lambda_t/maxRate
                    kSpk= kSpk+1;
                    spkTrial(kSpk) = t;
                end
            end
        end
        spkTrial             = spkTrial(~isnan(spkTrial));
        spkTime{nTrial}      = spkTrial;
        spkCounts(nTrial, :) = hist(spkTrial,timeBins)/binSize;
    end
end