function [dff, baseline]   = get_baseline (para)

    cont_ratio      = 0.7;
    peak            = para.peak; % removing 3 sec data from spikes
    spk             = para.t_ephys(peak);
    fmean           = para.fmean;
    tFrame          = para.t_frame;
    fneuropil       = para.fneuropil;
    fmean_comp      = fmean-fneuropil*cont_ratio;
    noSpikesTime    = true(length(para.t_frame),1);
    
    for nSpikeTime  = spk' %1:length(spk)
        noSpikesTime(tFrame>= nSpikeTime & tFrame<= nSpikeTime + 3) = false;
    end

%     baseline        = interp1(tFrame(noSpikesTime),fmean_comp(noSpikesTime),tFrame,'linear');
    baseline        = smooth(tFrame(noSpikesTime),fmean_comp(noSpikesTime),40,'sgolay', 3);
    baseline        = interp1(tFrame(noSpikesTime),baseline,tFrame,'linear');
    baselineNoNaN   = baseline(~isnan(baseline));
    baseline(isnan(baseline))= baselineNoNaN(end);
    
    dff             = (fmean_comp-baseline)./baseline;