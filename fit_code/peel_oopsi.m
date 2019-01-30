% 'Peeling' spike inference algorithm for calcium imaging data
% Modeling framework for simulating calcium data and evaluating the peeling algorithm
% Fritjof Helmchen, Henry L¸tcke
% Brain Research Institute, University of Zurich, Switzerland
% Nov 2013
% ------ Please refer to: ----------
% L¸tcke H, Gerhard F, Zenke F, Gerstner W, Helmchen F (2013) Inference of neuronal network spike dynamics
% and topology from calcium imaging data. Frontiers in Neural Circuits, 7:201.
% Grewe B, Langer D, Kasper H, Kampa B, Helmchen F (2010) High-speed in vivo calcium imaging reveals 
% neuronal network activity with near-milisecond precision. Nature Methods, 7(5): 399-405.
% ----------------------------------
% To simply run the code on a ca trace vector, checkout this test: 
% > test = open('PeelingExampleDataFrameYC36.mat')
% > [ca_p,exp_p,peel_p, data] = InitPeeling(test.drr, test.rate)
% > [ca_p,peel_p, data] = Peeling(test.drr, test.rate);
% -----------
% Here is an overview of the main parameters and their use (see also InitPeeling):
% A1 ... single AP calcium transient amplitude (in % dF/F)
% A1sigma ... variability of A1 from AP to AP. This is modeled as a normal distribution with mean A1 and s.d. A1sigma*A1. Leave empty to use sam A1 for each AP.
% tau1 ... decay time of calcium transient (in s)
% tau1sigma ... variability of tau1 from AP to AP. This is modeled as a normal distribution with mean tau1 and s.d. tau1sigma*tau1. Leave empty to use same tau1 for each AP.
% tauOn ... onset time of calcium transient (in s)
% dur ... duration of the simulation (in s)
% frameRate ... sampling rate of the simulated calcium signal.
% snr ... Signal-to-noise ratio of the noisy calcium trace. SNR is defined as A1/SDnoise
% spikeRate ... neuronal firing rate. To generate spike times, a Poisson process with this rate is used.
% spikeTimes ... it is also possible to specify spike times explicitely using a cell array. All spike times in s.
% recycleSpikeTimes ... flag to use the provided spike times (1) or generate new spike times at specified rate.
% offset ... this is the time (in s) that is added before the beginning of the simulation to reach a steady state. important for high firing rates only.
% reconAlg ... the spike reconstruction algorithm. this can be 'peeling' or 'none'.
% peelOptions ... structure with options for the peeling algorithm. Possible fields are: 
% peelOptions.schmitt = [1.75 -1 0.3]; % schmitt trigger settings (high and low thresholds in terms of s.d. and min. duration in s) 
% peelOptions.peel_p.optimizeSpikeTimes = 0; % perform spike time optimization after peeling? useful for data with high temporal resolution. requires the optimization toolbox in Matlab. 
% peelOptions.peel_p.fitonset = 1; % fit onset of calcium transient. this is another option for improving the timing and could be used instead of the optimization approach.
%
% In addition to modeling the calcium transient as single-exponential process, it is also possible to model 
% a double-exponential process with a fast and a slow decay (see for example Grewe et al., Nat Meth, 2010). 
% To do this, specify A1 / tau1 for the fast component and A2 / tau2 for the slow component.
% 
% After running the modelCalcium routine, output structure S contains additional fields: 
% data ... structure with simulated data: 
% dff ... simulated DFF at original temporal resolution 
% noisyDFF ... with noise added 
% noisyDFFlowResT ... with noise and at target sampling rate 
% recon ... structure with output of reconstruction algorithm 
% spikePredict ... predicted spike times by peeling 
% peel ... the residual trace
% -----------------------------------------------------------------------------
% 
% revision and compiled to peel_oopsi by:
% Ziqiang Wei
% weiz AT janelia DOT hhmi DOT org
%

function [ca_p,peel_p, data] = peel_oopsi(dff, rate, varargin)
% this is the main routine of the peeling algorithm
maxRate_peel   = Inf;
if rate > maxRate_peel
    peel_rate  = maxRate_peel;
    fit_rate   = rate;
    x          = 1/rate:1/rate:numel(dff)/rate;
    xi         = 1/peel_rate:1/peel_rate:max(x);
    peel_dff   = interp1(x,dff,xi);
else
    peel_rate  = rate;
    fit_rate   = rate;
    peel_dff   = dff;
end
[ca_p,exp_p,peel_p, data] = InitPeeling(peel_dff, peel_rate);
if nargin > 2
    for n = 1:numel(varargin)
        S = varargin{n};
        if n       == 1
            ca_p   = overrideFieldValues(ca_p,S);
        elseif n   == 2
            exp_p  = overrideFieldValues(exp_p,S);
        elseif n   == 3
            peel_p = overrideFieldValues(peel_p,S);
        end
    end
end
data.model              = 0;
data.spikes             = zeros(1,1000);
data.numspikes          = 0;
data.peel               = data.dff;
wsiz                    = round(peel_p.slidwinsiz*exp_p.acqrate); %#ok<NASGU>
checkwsiz               = round(peel_p.negintwin*exp_p.acqrate); %#ok<NASGU>
peel_p.smttmindurFrames = ceil(peel_p.smttmindur*exp_p.acqrate);
peel_p.smttlowMinEvents = 1;
[ca_p, peel_p, data]    = FindNextEvent(ca_p, exp_p, peel_p, data, 0);
if (peel_p.evtfound == 1)
    data.numspikes              = data.numspikes + 1;
    data.spikes(data.numspikes) = peel_p.nextevt;
    [ca_p, data]                = SingleCaTransient(ca_p, data, peel_p.nextevt);
    data.model                  = data.model + data.singleTransient;
end
maxiter         = 999999;
iter            = 0;
nexttimMem      = Inf;
nexttimCounter  = 0;
timeStepForward = 2./exp_p.acqrate;
while (peel_p.evtfound == 1)
    % check integral after subtracting Ca transient
    dummy               = data.peel - data.singleTransient;
    [~,startIdx]        = min(abs(data.tim-data.spikes(data.numspikes)));
    [~,stopIdx]         = min(abs(data.tim-(data.spikes(data.numspikes)+...
                          peel_p.intcheckwin)));
    if startIdx < stopIdx
        currentTim      = data.tim(startIdx:stopIdx);
        currentPeel     = dummy(startIdx:stopIdx);
        currentIntegral = trapz(currentTim,currentPeel);
    else
        % if this is true, startIdx is the last data point and we should
        % not accept it as a spike
        currentIntegral = ca_p.negintegral*peel_p.negintacc;
    end
    if currentIntegral > (ca_p.negintegral*peel_p.negintacc)
        data.peel       = data.peel - data.singleTransient;
        nexttim         = data.spikes(data.numspikes) - peel_p.stepback;
        if (nexttim < 0)
            nexttim     = 0;
        end
    else
        data.spikes(data.numspikes) = [];
        data.numspikes = data.numspikes-1;
        data.model     = data.model - data.singleTransient;
        nexttim        = peel_p.nextevt + timeStepForward;
    end
    peel_p.evtaccepted = 0;
    [ca_p, peel_p, data] = FindNextEvent(ca_p, exp_p, peel_p, data, nexttim);
    if peel_p.evtfound
            data.numspikes              = data.numspikes + 1;
            data.spikes(data.numspikes) = peel_p.nextevt;
            [ca_p, data]                = SingleCaTransient(ca_p, data, peel_p.nextevt);
            data.model                  = data.model + data.singleTransient;
    else
        break
    end    
    iter = iter + 1;
    if (iter > maxiter), break, end
    if nexttim == nexttimMem
        nexttimCounter = nexttimCounter + 1;
    else
       nexttimMem = nexttim; 
       nexttimCounter = 0;
    end
    if nexttimCounter > 50
       nexttim = nexttim + timeStepForward;  %#ok<NASGU>
    end
%     if (iter > maxiter)
% %         warning('Reached maxiter (%1.0f). nexttim=%1.2f. Timeout!',maxiter,nexttim);
% %         save
% %         error('Covergence failed!')
%         break
%     end
end
if length(data.spikes) > data.numspikes
    data.spikes(data.numspikes+1:end) = [];
end
% go back to original frame rate
if rate > maxRate_peel
    spikes                    = data.spikes;
    [ca_p,exp_p,peel_p, data] = InitPeeling(dff, fit_rate);
    if nargin > 2
        for n = 1:numel(varargin)
            S = varargin{n};
            if n == 1
                ca_p    = overrideFieldValues(ca_p,S);
            elseif n == 2
                exp_p   = overrideFieldValues(exp_p,S);
            elseif n == 3
                peel_p  = overrideFieldValues(peel_p,S);
            end
        end
    end
    data.spikes = spikes;
end
% optimization of reconstructed spike times to improve timing
optMethod  = 'pattern search';
optMaxIter = 100000;
lowerT     = 1; % relative to x0
upperT     = 1; % relative to x0
if numel(data.spikes) && peel_p.optimizeSpikeTimes
    data.spikes   = PeelingOptimizeSpikeTimes(data.dff,data.spikes,lowerT,upperT,...
        exp_p.acqrate,ca_p.onsettau,ca_p.amp1,ca_p.tau1,optMethod,optMaxIter);
end
% fit onset to improve timing accuracy
if peel_p.fitonset
    onsetfittype  = fittype('modelCalciumTransient(t,onsettime,onsettau,amp1,tau1)',...
        'independent','t','coefficients',{'onsettime','onsettau','amp1'},...
        'problem',{'tau1'});
    wleft         = round(peel_p.fitwinleft*exp_p.acqrate);     % left window for onset fit
    wright        = round(peel_p.fitwinright*exp_p.acqrate);    % right window for onset fit
    for i = 1:numel(data.spikes)
        [~,idx]   = min(abs(data.spikes(i)-data.tim));
        if (idx-wleft) < 1
            currentwin = data.dff(1:idx+wright);
            currenttim = data.tim(1:idx+wright);
        elseif (idx+wright) > numel(data.dff)
            currentwin = data.dff(idx-wleft:numel(data.dff));
            currenttim = data.tim(idx-wleft:numel(data.dff));
            currentwin = currentwin - mean(data.dff(idx-wleft:idx));
        else
            currentwin = data.dff(idx-wleft:idx+wright);
            currenttim = data.tim(idx-wleft:idx+wright);
            currentwin = currentwin - mean(data.dff(idx-wleft:idx));
        end
        lowerBounds    = [currenttim(1) 0.1*ca_p.onsettau 0.5*ca_p.amp1];
        upperBounds    = [currenttim(end) 5*ca_p.onsettau 10*ca_p.amp1];
        startPoint     = [data.spikes(i) ca_p.onsettau ca_p.amp1];
        problemParams  = {ca_p.tau1};
        fOptions       = fitoptions('Method','NonLinearLeastSquares','Lower',...
                         lowerBounds, 'Upper',upperBounds,'StartPoint',startPoint);
        [fitonset,gof] = fit(currenttim',currentwin',onsetfittype,...
                         'problem',problemParams,fOptions);        
        if gof.rsquare >= 0.95
            data.spikes(i) = fitonset.onsettime;
        end
    end
end
% loop to create spike train vector from spike times
data.spiketrain = zeros(1,numel(data.tim));
for i = 1:numel(data.spikes)
    [~,idx] = min(abs(data.spikes(i)-data.tim));
    data.spiketrain(idx) = data.spiketrain(idx)+1;
end
% re-derive model and residuals after optimization
modelTransient = spkTimes2Calcium(0,ca_p.onsettau,ca_p.amp1,ca_p.tau1,...
                 ca_p.amp2,ca_p.tau2,exp_p.acqrate,max(data.tim));
data.model     = conv(data.spiketrain,modelTransient);
data.model     = data.model(1:length(data.tim));
data.peel      = data.dff - data.model;
end

function [ca_p,exp_p,peel_p, data] = InitPeeling(dff, rate)
% ca_p: parameters of elementary (1 AP) calcium transient
ca_p.onsetposition =0.0;    % onset position(s)
ca_p.onsettau=0.0000001;    % onset tau (s)
ca_p.offset=0;              % baseline offset (%)
ca_p.amp1=2.5;              % amplitude 1  (%)
ca_p.tau1=0.6;              % tau1 (s)
ca_p.amp2=0;                % amplitude 2 (%)
ca_p.tau2=1.0;              % tau2 (s)
ca_p.integral=0.0;          % integral below curve (%s)
ca_p.scale=1.0;             % scale factor to scale entire trace (s)
% exp_p: experiment parameters, including dye properties and data acquisition 
exp_p.numpnts = length(dff); % numpoints
exp_p.acqrate = rate;        % acquisition rate (Hz)
% exp_p.noiseSD = 1.2;        % noise stdev of DF/F trace (in percent), should be specified by the user
exp_p.noiseSD = std(dff);   % ZW: change
exp_p.indicator = 'OGB-1';  % calcium indicator
exp_p.dffmax = 93;          % saturating dff max (in percent)
exp_p.kd = 200;             % dye dissociation constant (nM)
exp_p.carest = 50;          % presumed resting calcium concentration (nM)
% peel_p: parameters for peeling algorithm
% peel_p.padding = 20;        % number of points for padding before and after
peel_p.padding = 0;        % number of points for padding before and after
% peel_p.sdnoise = 1.4;       % expected SD baseline noise level
% peel_p.smtthigh = 2.4;      % Schmitt trigger - high threshold (multiple of exp_p.noiseSD)
% peel_p.smttlow = -1.2;      % Schmitt trigger - low threshold (multiple of exp_p.noiseSD)
peel_p.smtthigh = 1/rate/2*exp_p.noiseSD; % ZW: change
peel_p.smttlow = -1/rate/2*exp_p.noiseSD; % ZW: change
peel_p.smttbox= 10;          % Schmitt trigger - smoothing box size (in points)
peel_p.smttmindur= 1/rate*2;     % Schmitt trigger - minimum duration (s)
% HL: 2012-05-04
% new parameter: max. frames fro smttmindur
% if the frame rate is high, number of frames for smttmindur can be
% large, thereby increasing false negatives
% if smttminFrames is set, use binning to reduce the number of
% frames to this value for high frame rates
% peel_p.smttminFrames = 20;
peel_p.smttnumevts= 0;      % Schmitt trigger - number of found events
% peel_p.slidwinsiz= 10.0;    % sliding window size - event detection (s)
peel_p.slidwinsiz= 2.0;    % sliding window size - event detection (s)
peel_p.maxbaseslope= 0.5;   % maximum baseslope %/s
peel_p.evtfound=0;          % flag - 1: crossing found 
peel_p.nextevt=0;           % next crossing found (s)
peel_p.nextevtframe=0;      % next crossing found (frame number)
peel_p.intcheckwin=0.5;     % window to the right - for integral comparison (s)
peel_p.intacclevel=0.5;     % event integral acceptance level (0.5 means 50%)
peel_p.fitonset=0;          % flag - 1: do onset fit, only useful if 1/frameRate <= rise of CacliumTransient
peel_p.fitwinleft=0.5;     % left window for onset fit (s)
peel_p.fitwinright=0.5;    % right window for onset fit (s)
peel_p.negintwin=0.5;       % window to the right - for negativeintegral check(s)
peel_p.negintacc=0.5;       % negative acceptance level (0.5 means 50%)
peel_p.stepback=1.5;        % stepsize backwards for next iteration (s)
peel_p.fitupdatetime=2;     % how often the linear fit is updated (s)
peel_p.optimizeSpikeTimes = true;
% data: data struct 
data.dff = dff;
data.tim = 1:length(data.dff); 
data.tim = data.tim./exp_p.acqrate;
data.intdff = 1:length(data.dff);                % integral curve
data.singleTransient = zeros(1,exp_p.numpnts);
data.model = zeros(1,exp_p.numpnts);
data.spiketrain = zeros(1,exp_p.numpnts);
data.slide = zeros(1,exp_p.numpnts);            % sliding curve, zero corrected
data.temp = 1:length(data.dff);                 % temporary wave
data.peel = zeros(1,exp_p.numpnts);
data.peel = data.dff;
data.spikes = zeros(1,1000);                    % array for found spikes times
data.numspikes = 0;                             % number of spikes found
end

function Sout = overrideFieldValues(Sout,Sin)
fieldIDs = fieldnames(Sin);
for n = 1:numel(fieldIDs)
    Sout.(fieldIDs{n}) = Sin.(fieldIDs{n});
end
end

function [ca_p, peel_p,data] = FindNextEvent(ca_p, exp_p, peel_p, data, starttim)
% exp_p - parameter of data set (either experimental or simulated)
% alg_p - algorithm parameters/settings
% starttim - time point for starting search (s)
peel_p.evtfound=0;
if (starttim < 0) || (starttim > exp_p.numpnts/exp_p.acqrate)
    return
end
wsiz = round(peel_p.slidwinsiz*exp_p.acqrate);
peel_p.padding = wsiz;
data = PaddingTraces(exp_p, peel_p, data);
checkwsiz = round(peel_p.intcheckwin*exp_p.acqrate);
ca_p = IntegralofCaTransient(ca_p, peel_p);
nstart = round(starttim*exp_p.acqrate+0.5)+wsiz;    % start as frame number
updateFit = peel_p.fitupdatetime; % update fit only from time to time
updateFitFrames = ceil(updateFit*exp_p.acqrate);
frameCounter = updateFitFrames+1;
for n = nstart:length(data.peel_pad)-wsiz
    if frameCounter > updateFitFrames
        frameCounter = 0;
        currentwin = data.peel_pad(n-wsiz:n-1);
        currenttim = data.tim_pad(n-wsiz:n-1);
        linefit = polyfit(currenttim,currentwin,1);
        tmpslope = linefit(1);
        if tmpslope > peel_p.maxbaseslope
            tmpslope = peel_p.maxbaseslope;
        elseif tmpslope < -peel_p.maxbaseslope
            tmpslope = -peel_p.maxbaseslope;
        end
    else
        frameCounter = frameCounter + 1;
    end
    currentoffset = tmpslope*data.tim_pad(n-1) + linefit(2);    
    % Schmitt trigger Loop
    if (data.peel_pad(n)-currentoffset>peel_p.smtthigh)
        if n+peel_p.smttmindurFrames <= length(data.peel_pad)
            currentDff = data.peel_pad(n:n+peel_p.smttmindurFrames);
        else
            currentDff = data.peel_pad(n:end);
        end
        if length(find(currentDff<=peel_p.smttlow)) > peel_p.smttlowMinEvents
            n = n + find(currentDff<=peel_p.smttlow,1,'last'); %#ok<FXSET>
            if n > length(data.peel_pad)-wsiz
                break
            end
            frameCounter = frameCounter + find(currentDff<=peel_p.smttlow,1,'last');
            continue
        end
        data.slide_pad = data.peel_pad - currentoffset;
        data.temp_pad = tmpslope*data.tim_pad + linefit(2) - currentoffset;
        data.slide_pad = data.slide_pad - data.temp_pad;
        currentIntegral = trapz(data.tim_pad(n:n+checkwsiz),...
            data.slide_pad(n:n+checkwsiz));
        if currentIntegral>(ca_p.integral*peel_p.intacclevel)
            peel_p.evtfound=1;
            break
        end
    end
end
if peel_p.evtfound
    peel_p.nextevtframe = n-wsiz-1;
    peel_p.nextevt = (n-wsiz-1) / exp_p.acqrate;
end
data.peel(1:end) = data.peel_pad(peel_p.padding+1:peel_p.padding+exp_p.numpnts);
end

function [ca_p, data] = SingleCaTransient(ca_p, data, starttim)
% ca_p - parameter for calcium dynamics  
% data - data and analysis traces
% starttim - start of the calcium transient
ca_p.onsetposition = starttim;
data.singleTransient = repmat(ca_p.offset,1,numel(data.tim));
% faster version - Felipe Gerhard
ind = data.tim > ca_p.onsetposition; % relevant indices
data.singleTransient(ind) = ca_p.offset + ...
    ca_p.scale.*(1-exp(-(data.tim(ind)-ca_p.onsetposition)./ca_p.onsettau)) .* ...
          (ca_p.amp1.*exp(-(data.tim(ind)-ca_p.onsetposition)./ca_p.tau1)+ ...
          ca_p.amp2.*exp(-(data.tim(ind)-ca_p.onsetposition)./ca_p.tau2));
end

function [spkTout,output] = PeelingOptimizeSpikeTimes(dff,spkTin,lowerT,upperT,...
    rate,tauOn,A1,tau1,optimMethod,maxIter)
% optimization of spike times found by Peeling algorithm
% minimize the sum of the residual squared
% while several optimization algorithms are implemented (see below), we have only used pattern
% search. Other algorithms are only provided for convenience and are not tested sufficiently.
t              = (1:numel(dff))./rate;
modelTransient = modelCalciumTransient(t,t(1),tauOn,A1,tau1);
modelTransient = modelTransient';
spkTout        = spkTin;
spkVector      = zeros(1,numel(t));
for i = 1:numel(spkTin)
    [~,idx]    = min(abs(spkTin(i)-t));
    spkVector(idx) = spkVector(idx)+1;
end
model          = conv(spkVector,modelTransient);
model          = model(1:length(t));
residual       = dff - model;
resInit        = sum(residual.^2);
% start optimization
x0 = spkTin;
lbound         = spkTin - lowerT;
lbound(lbound<0) = 0; %#ok<NASGU>
ubound         = spkTin + upperT;
ubound(ubound>max(t)) = max(t); %#ok<NASGU>
lbound         = zeros(size(spkTin));
ubound         = repmat(max(t),size(spkTin));
opt_args.dff   = dff;
opt_args.rate  = rate;
opt_args.tauOn = tauOn;
opt_args.A1    = A1;
opt_args.tau1  = tau1;
switch lower(optimMethod)
    case 'simulated annealing'
        options = saoptimset;
    case 'pattern search'
        options = psoptimset;
    case 'genetic'
        options = gaoptimset;
    otherwise
        error('Optimization method %s not supported.',optimMethod)
end
% options for optimization algorithms
% not all options are used for all algorithms
options.Display        = 'off';
options.MaxIter        = maxIter;
options.MaxIter        = Inf;
options.UseParallel    = 'always';
options.ObjectiveLimit = 0;
% options.TimeLimit = 10; % in s / default is Inf
% experimental
options.MeshAccelerator = 'on'; % off by default
options.TolFun          = 1e-9; % default is 1e-6
options.TolMesh         = 1e-9; % default is 1e-6
options.TolX            = 1e-9; % default is 1e-6
% options.MaxFunEvals   = numel(spkTin)*100; % default is 2000*numberOfVariables
% options.MaxFunEvals   = 20000;
options.Display         = 'none';
% options.Display       = 'final';
% options.PlotFcns      = {@psplotbestf @psplotbestx};
% options.OutputFcns    = @psoutputfcn_peel;
switch lower(optimMethod)
    case 'simulated annealing'
        [x, fval , ~, output] = simulannealbnd(...
            @(x) objectiveFunc(x,opt_args),x0,lbound,ubound,options);
    case 'pattern search'
        [x, fval , ~, output] = patternsearch(...
            @(x) objectiveFunc(x,opt_args),x0,[],[],[],[],lbound,...
            ubound,[],options);
    case 'genetic'
        [x, fval , ~, output] = ga(...
            @(x) objectiveFunc(x,opt_args),numel(x0),[],[],[],[],lbound,...
            ubound,[],options);
end
if fval < resInit
    spkTout = x;
else
    disp('Optimization did not improve residual. Keeping input spike times.')
end
end

function residual = objectiveFunc(spkTin,opt_args)
dff            = opt_args.dff;
rate           = opt_args.rate;
tauOn          = opt_args.tauOn;
A1             = opt_args.A1;
tau1           = opt_args.tau1;
t              = (1:numel(dff))./rate;
modelTransient = spkTimes2Calcium(0,tauOn,A1,tau1,0,0,rate,max(t));
spkVector      = zeros(1,numel(t));
for i          = 1:numel(spkTin)
    [~,idx]        = min(abs(spkTin(i)-t));
    spkVector(idx) = spkVector(idx)+1;
end
model          = conv(spkVector,modelTransient);
model          = model(1:length(t));
residual       = dff-model;
residual       = sum(residual.^2);
end

function [y, x] = spkTimes2Calcium(spkT,tauOn,ampFast,tauFast,ampSlow,...
    tauSlow,frameRate,duration)
x = 0:(1/frameRate):duration;
y = (1-(exp(-(x-spkT)./tauOn))).*...
    (ampFast.*exp(-(x-spkT)./tauFast))+(ampSlow.*exp(-(x-spkT)./tauSlow)); 
y(x<spkT)   = 0;
y(isnan(y)) = 0;
end

function y = modelCalciumTransient(t,onsettime,onsettau,amp1,tau1)
offset = 0;
y      = repmat(offset,numel(t),1);
ind    = t > onsettime;
y(ind) = offset + (1-exp(-(t(ind)-onsettime)./onsettau)) .* ...
          (amp1.*exp(-(t(ind)-onsettime)./tau1));
end

function data = PaddingTraces(exp_p, peel_p, data)
% padding of traces in working array
data.dff_pad = zeros(1,exp_p.numpnts+2*peel_p.padding);
data.dff_pad(peel_p.padding+1:peel_p.padding+exp_p.numpnts) = ...
    data.dff(1:exp_p.numpnts);
data.peel_pad = zeros(1,exp_p.numpnts+2*peel_p.padding);
data.peel_pad(peel_p.padding+1:peel_p.padding+exp_p.numpnts) = ...
    data.peel(1:exp_p.numpnts);
data.slide_pad = zeros(1,exp_p.numpnts+2*peel_p.padding);
data.temp_pad = zeros(1,exp_p.numpnts+2*peel_p.padding);
data.tim_pad = -peel_p.padding+1:length(data.peel_pad)-peel_p.padding; 
data.tim_pad = data.tim_pad./exp_p.acqrate;
end

function ca_p = IntegralofCaTransient(ca_p, peel_p)
% ca_p - parameter for calcium dynamics  
% intvl = window from onset for integral calculation (s)
% calculate integral for window:
ca_p.integral = ca_p.amp1*(ca_p.tau1*(1-exp(-peel_p.intcheckwin/ca_p.tau1)) - ca_p.tau1/(1+ca_p.tau1/ca_p.onsettau)* ...
                (1-exp(-peel_p.intcheckwin*(1+ca_p.tau1/ca_p.onsettau)/ca_p.tau1)) );
ca_p.integral = ca_p.integral + ...
                ca_p.amp2*(ca_p.tau2*(1-exp(-peel_p.intcheckwin/ca_p.tau2)) - ca_p.tau2/(1+ca_p.tau2/ca_p.onsettau)* ...
                (1-exp(-peel_p.intcheckwin*(1+ca_p.tau2/ca_p.onsettau)/ca_p.tau2)) );
ca_p.integral = ca_p.integral * ca_p.scale;
% negative integral for subtraction check
ca_p.negintegral = ca_p.amp1*(ca_p.tau1*(1-exp(-peel_p.negintwin/ca_p.tau1)) - ca_p.tau1/(1+ca_p.tau1/ca_p.onsettau)* ...
                (1-exp(-peel_p.negintwin*(1+ca_p.tau1/ca_p.onsettau)/ca_p.tau1)) );
ca_p.negintegral = ca_p.negintegral + ...
                ca_p.amp2*(ca_p.tau2*(1-exp(-peel_p.negintwin/ca_p.tau2)) - ca_p.tau2/(1+ca_p.tau2/ca_p.onsettau)* ...
                (1-exp(-peel_p.negintwin*(1+ca_p.tau2/ca_p.onsettau)/ca_p.tau2)) );
ca_p.negintegral = ca_p.negintegral * -1.0 * ca_p.scale;
end