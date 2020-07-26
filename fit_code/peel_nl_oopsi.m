% revision based on Bei-Jun's peeling code
% Ziqiang Wei
% weiz AT janelia DOT hhmi DOT org
%

function [ca_p,peel_p, data] = peel_nl_oopsi(dff, rate, varargin)
maxRate_peel = Inf;
if rate > maxRate_peel
    peel_rate = maxRate_peel;
    fit_rate = rate;
    x = 1/rate:1/rate:numel(dff)/rate;
    xi = 1/peel_rate:1/peel_rate:max(x);
    peel_dff = interp1(x,dff,xi);
else
    peel_rate = rate;
    fit_rate = rate;
    peel_dff = dff;
end
[ca_p,exp_p,peel_p, data] = InitPeeling(peel_dff, peel_rate);
if nargin > 2
    for n = 1:numel(varargin)
        S = varargin{n};
        if n == 1
            ca_p = overrideFieldValues(ca_p,S);
        elseif n == 2
            exp_p = overrideFieldValues(exp_p,S);
        elseif n == 3
            peel_p = overrideFieldValues(peel_p,S);
        end
    end
end
data.model = 0;
data.freecamodel = ca_p.ca_rest; 
data.spikes = zeros(1,1000);
data.numspikes = 0;
data.peel = data.dff;
wsiz = round(peel_p.slidwinsiz*exp_p.acqrate); %#ok<NASGU>
checkwsiz = round(peel_p.negintwin*exp_p.acqrate); %#ok<NASGU>
peel_p.smttmindurFrames = ceil(peel_p.smttmindur*exp_p.acqrate);
peel_p.smttlowMinEvents = 1;
nexttim = 1/exp_p.acqrate;
[ca_p, peel_p, data] = FindNextEvent(ca_p, exp_p, peel_p, data, nexttim);
if (peel_p.evtfound == 1)
    data.numspikes = data.numspikes + 1;
    data.spikes(data.numspikes) = peel_p.nextevt;
    [ca_p, exp_p, data] = SingleFluorTransient(ca_p, exp_p, data, peel_p.spk_recmode, peel_p.nextevt);
    data.model = data.model + data.singleTransient;
end
maxiter = 999999;
iter = 0;
nexttimMem = Inf;
nexttimCounter = 0;
timeStepForward = 2./exp_p.acqrate;
while (peel_p.evtfound == 1)
    % check integral after subtracting Ca transient
    if strcmp(peel_p.spk_recmode, 'linDFF')
    elseif strcmp(peel_p.spk_recmode, 'satDFF')
       ca_p.onsetposition = peel_p.nextevt;
       ca_p = IntegralofCaTransient(ca_p, peel_p, exp_p, data);
    end
    dummy = data.peel - data.singleTransient;
    [~,startIdx] = min(abs(data.tim-data.spikes(data.numspikes)));
    [~,stopIdx] = min(abs(data.tim-(data.spikes(data.numspikes)+...
        peel_p.intcheckwin)));
    if startIdx < stopIdx
        currentTim = data.tim(startIdx:stopIdx);
        currentPeel = dummy(startIdx:stopIdx);
        currentIntegral = trapz(currentTim,currentPeel);
    else
        % if this is true, startIdx is the last data point and we should
        % not accept it as a spike
        currentIntegral = ca_p.negintegral*peel_p.negintacc;
    end
    if currentIntegral > (ca_p.negintegral*peel_p.negintacc)
        data.peel = data.peel - data.singleTransient;
        nexttim = data.spikes(data.numspikes) - peel_p.stepback;
        if (nexttim < 0)
            nexttim = 1/exp_p.acqrate;
        end
    else
        data.spikes(data.numspikes) = [];
        data.numspikes = data.numspikes-1;
        data.model = data.model - data.singleTransient;
        nexttim = peel_p.nextevt + timeStepForward;
    end
    peel_p.evtaccepted = 0;
    [ca_p, peel_p, data] = FindNextEvent(ca_p, exp_p, peel_p, data, nexttim);
    if peel_p.evtfound
            data.numspikes = data.numspikes + 1;
            data.spikes(data.numspikes) = peel_p.nextevt;
            [ca_p, exp_p, data] = SingleFluorTransient(ca_p, exp_p, data, peel_p.spk_recmode, peel_p.nextevt);
            data.model = data.model + data.singleTransient;
    else
        break
    end
    iter = iter + 1;
    if nexttim == nexttimMem
        nexttimCounter = nexttimCounter + 1;
    else
       nexttimMem = nexttim; 
       nexttimCounter = 0;
    end
    if nexttimCounter > 50
       nexttim = nexttim + timeStepForward;  %#ok<NASGU>
    end    
    if (iter > maxiter)
        break
    end
end

if length(data.spikes) > data.numspikes
    data.spikes(data.numspikes+1:end) = [];
end
% go back to original frame rate
if rate > maxRate_peel
    spikes = data.spikes;
    [ca_p,exp_p,peel_p, data] = InitPeeling(dff, fit_rate);
    if nargin > 2
        for n = 1:numel(varargin)
            S = varargin{n};
            if n == 1
                ca_p = overrideFieldValues(ca_p,S);
            elseif n == 2
                exp_p = overrideFieldValues(exp_p,S);
            elseif n == 3
                peel_p = overrideFieldValues(peel_p,S);
            end
        end
    end
    data.spikes = spikes;
end
% optimization of reconstructed spike times to improve timing
optMethod = 'pattern search';
optMaxIter = 100000;
%lowerT = 1; % relative to x0
%upperT = 1; % relative to x0
lowerT = 0.1; % relative to x0
upperT = 0.1; % relative to x0
if numel(data.spikes) && peel_p.optimizeSpikeTimes
    if strcmp(peel_p.spk_recmode, 'linDFF')
        spikes = PeelingOptimizeSpikeTimes(data.dff,data.spikes,lowerT,upperT,...
                    exp_p.acqrate,ca_p.onsettau,ca_p.amp1,ca_p.tau1,optMethod,optMaxIter);
    elseif strcmp(peel_p.spk_recmode, 'satDFF')
        spikes = PeelingOptimizeSpikeTimesSaturation(data.dff,data.spikes,lowerT,upperT,...
                    ca_p.ca_amp,ca_p.ca_gamma,ca_p.ca_onsettau,ca_p.ca_rest,ca_p.ca_kappas, exp_p.kd,...
                    exp_p.conc,exp_p.dffmax, exp_p.acqrate, length(data.dff)./exp_p.acqrate, optMethod,optMaxIter);
    else
        error('Undefined mode');
    end
    data.spikes = sort(spikes);
end
% fit onset to improve timing accuracy
if peel_p.fitonset
    onsetfittype = fittype('modelCalciumTransient(t,onsettime,onsettau,amp1,tau1)',...
        'independent','t','coefficients',{'onsettime','onsettau','amp1'},...
        'problem',{'tau1'});
    wleft = round(peel_p.fitwinleft*exp_p.acqrate);     % left window for onset fit
    wright = round(peel_p.fitwinright*exp_p.acqrate);    % right window for onset fit
    for i = 1:numel(data.spikes)
        [~,idx] = min(abs(data.spikes(i)-data.tim));
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
        lowerBounds = [currenttim(1) 0.1*ca_p.onsettau 0.5*ca_p.amp1];
        upperBounds = [currenttim(end) 5*ca_p.onsettau 10*ca_p.amp1];
        startPoint = [data.spikes(i) ca_p.onsettau ca_p.amp1];
        problemParams = {ca_p.tau1};
        
        fOptions = fitoptions('Method','NonLinearLeastSquares','Lower',...
            lowerBounds,...
            'Upper',upperBounds,'StartPoint',startPoint);
        [fitonset,gof] = fit(currenttim',currentwin',onsetfittype,...
            'problem',problemParams,fOptions);
        if gof.rsquare < 0.95
%                         fprintf('\nBad onset fit (t=%1.3f, r^2=%1.3f)\n',...
%                             data.spikes(i),gof.rsquare);
        else
            %             fprintf('\nGood onset fit (r^2=%1.3f)\n',gof.rsquare);
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
if strcmp(peel_p.spk_recmode, 'linDFF')
    modelTransient = spkTimes2Calcium(0,ca_p.onsettau,ca_p.amp1,ca_p.tau1,...
                                     ca_p.amp2,ca_p.tau2,exp_p.acqrate,max(data.tim));
    data.model = conv(data.spiketrain,modelTransient);
    data.model = data.model(1:length(data.tim));
elseif strcmp(peel_p.spk_recmode, 'satDFF')
    modeltmp = spkTimes2FreeCalcium(data.spikes,ca_p.ca_amp,ca_p.ca_gamma,ca_p.ca_onsettau,ca_p.ca_rest, ca_p.ca_kappas,...
                                    exp_p.kd, exp_p.conc,exp_p.acqrate,max(data.tim));
    data.model = Calcium2Fluor(modeltmp,ca_p.ca_rest,exp_p.kd, exp_p.dffmax);
end

data.peel = data.dff - data.model;
end

function Sout = overrideFieldValues(Sout,Sin)
fieldIDs = fieldnames(Sin);
for n = 1:numel(fieldIDs)
    Sout.(fieldIDs{n}) = Sin.(fieldIDs{n});
end
end

function fout = Calcium2Fluor(ca,ca_rest,kd, dffmax)
fout = dffmax.*(ca - ca_rest)./(ca + kd);
end

function [t,X] = CalciumDecay(p_gamma,p_carest,p_cacurrent,p_kappas,p_kd,p_conc,tspan)
options=odeset('RelTol',1e-6);                          % set an error
Xo = p_cacurrent;                                       % initial conditions
mypar = [p_gamma,p_carest,p_kappas,p_kd,p_conc];        % parameters
[t,X] = ode45(@Relax2CaRest,tspan,Xo,options, mypar);   % call the solver, tspan should contain time vector with more than two elements
function [dx_dt]= Relax2CaRest(t,x,pp) %#ok<INUSL>
    %%% ZW: something wrong with this equation
    % paramters pp: 1 - gamma, 2 - ca_rest, 3 - kappaS, 4 - kd, 
    %               5 - indicator total concentration (all conc in nM) 
    dx_dt =  -pp(1)* (x - pp(2))/(1 + pp(3) + pp(4)*pp(5)/(x + pp(4))^2); 
    return
end
end

function [d,ib] = findClosest(a,b) %#ok<DEFNU>
m = size(a,2); n = size(b,2);
[~,p] = sort([a,b]);
q = 1:m+n; q(p) = q;
t = cumsum(p>m);
r = 1:n; r(t(q(m+1:m+n))) = r;
s = t(q(1:m));
id = r(max(s,1));
iu = r(min(s+1,n));
[d,it] = min([abs(a-b(id));abs(b(iu)-a)]);
ib = id+(it-1).*(iu-id);
end

function [ca_p, peel_p,data] = FindNextEvent(ca_p, exp_p, peel_p, data, starttim)
peel_p.evtfound=0;
if (starttim < 0) || (starttim > exp_p.numpnts/exp_p.acqrate)
    return
end
wsiz = round(peel_p.slidwinsiz*exp_p.acqrate);
peel_p.padding = wsiz;
data = PaddingTraces(exp_p, peel_p, data);
checkwsiz = round(peel_p.intcheckwin*exp_p.acqrate);
ca_p.onsetposition = 1./exp_p.acqrate;
ca_p = IntegralofCaTransient(ca_p, peel_p, exp_p, data);
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
        
        %         if any(currentDff<=peel_p.smttlow)
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
        if strcmp(peel_p.spk_recmode, 'linDFF')
        elseif strcmp(peel_p.spk_recmode, 'satDFF')
            ca_p.onsetposition = (n-wsiz) ./ exp_p.acqrate;
            ca_p = IntegralofCaTransient(ca_p, peel_p, exp_p, data);
        end
        if currentIntegral>(ca_p.integral*peel_p.intacclevel)
            peel_p.evtfound=1;
            break
        end
        %         if (data.temp_pad(n+checkwsiz)-data.temp_pad(n))>(ca_p.integral*peel_p.intacclevel)
        %             peel_p.evtfound=1;
        %             break
        %         end
    end
end
if peel_p.evtfound
    peel_p.nextevtframe = n-wsiz-1;
    peel_p.nextevt = (n-wsiz-1) / exp_p.acqrate;
end
data.peel(1:end) = data.peel_pad(peel_p.padding+1:peel_p.padding+exp_p.numpnts);
end

function caout = Fluor2Calcium(f,ca_rest,kd, dffmax)
caout = (ca_rest + kd.*f./dffmax)./(1 - f./dffmax);
end

function [ca_p,exp_p,peel_p, data] = InitPeeling(dff, rate)
% ca_p: parameters of elementary (1 AP) calcium transient
ca_p.onsetposition =0.0;    % onset position(s)
%ca_p.usefreeca = 0;          % flag, 1 - use free calcium conc calculations and conversion to DF/F 
ca_p.ca_genmode = 'satDFF';   % flag for spike generation mode: 'linDFF' - simple linear DFF, or 'satDFF' - saturating indicator 
ca_p.ca_onsettau=0.02;      % Ca transient - onset tau (s)
ca_p.ca_amp=7600;          % Ca transient - total amplitude 1 (nM)
ca_p.ca_gamma=400;          % Ca transient - extrusion rate (1/s)
ca_p.ca_amp1=0;             % Ca transient - free Ca amplitude 1  (nM)
ca_p.ca_tau1=0;             % Ca transient - free Ca tau (s)
ca_p.ca_kappas=100;         % Ca transient - endogenous Ca-binding ratio 
ca_p.ca_rest = 50;          % presumed resting calcium concentration (nM)
ca_p.ca_current = 50;       % current calcium concentration (nM)   
% now parameters for Indicator DF/F(or DR/R); used if 'useFreeCalcium' = 0; otherwise conversion equation is used                            
% ca_p.onsettau=0.02;         % onset tau (s)
ca_p.onsettau=0;
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
exp_p.noiseSD = std(dff);    % noise stdev of DF/F trace (in percent), should be specified by the user
exp_p.indicator = 'OGB-1';  % calcium indicator
exp_p.dffmax = 93;          % saturating dff max (in percent)
exp_p.kd = 250;             % dye dissociation constant (nM)
exp_p.conc = 50000;         % dye total concentration (nM)
exp_p.kappab = exp_p.kd.*exp_p.conc./(ca_p.ca_rest+exp_p.kd).^2;           % exogenous (dye) Ca-binding ratio
if strcmp(ca_p.ca_genmode, 'linDFF')
elseif strcmp(ca_p.ca_genmode, 'satDFF')
    ca_p.ca_amp1=ca_p.ca_amp./(1+ca_p.ca_kappas+exp_p.kappab);             % init for consistency
    ca_p.ca_tau1=(1+ca_p.ca_kappas+exp_p.kappab)./ca_p.ca_gamma;
end
% peel_p: parameters for peeling algorithm
peel_p.spk_recmode = 'satDFF'; % flag,for spike reconstruction mode: 'linearDFF', or 'satDFF'  
peel_p.padding = 0;        % number of points for padding before and after
% peel_p.sdnoise = 1.4;       % expected SD baseline noise level
peel_p.smtthigh = 1/rate/20*exp_p.noiseSD;      % Schmitt trigger - high threshold (multiple of exp_p.noiseSD), 
peel_p.smttlow = -1*exp_p.noiseSD;      % Schmitt trigger - low threshold (multiple of exp_p.noiseSD), 
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
peel_p.slidwinsiz= 3.0;    % sliding window size - event detection (s)
peel_p.maxbaseslope= 0.5;   % maximum baseslope %/s
peel_p.evtfound=0;          % flag - 1: crossing found 
peel_p.nextevt=0;           % next crossing found (s)
peel_p.nextevtframe=0;      % next crossing found (frame number)
peel_p.intcheckwin=0.5;     % window to the right - for integral comparison (s)
peel_p.intacclevel=0.5;     % event integral acceptance level (0.5 means 50%)
peel_p.fitonset=0;          % flag - 1: do onset fit, only useful if 1/frameRate <= rise of CacliumTransient
peel_p.fitwinleft=0.5;     % left window for onset fit (s)
peel_p.fitwinright=0.5;    % right window for onset fit (s)
peel_p.negintwin=0.1;       % window to the right - for negativeintegral check(s)
peel_p.negintacc=5;       % negative acceptance level (0.5 means 50%)
peel_p.stepback=5.0;        % stepsize backwards for next iteration (s)
peel_p.fitupdatetime=0.5;     % how often the linear fit is updated (s)
peel_p.optimizeSpikeTimes = 0;  % flag - use optimization (pattern search)
peel_p.doPlot = 0;
% data: data struct 
data.dff = dff;
data.freeca = zeros(1,exp_p.numpnts);           % free calcium transient, from which dff will need to be calculated 
data.tim = 1:length(data.dff); 
data.tim = data.tim./exp_p.acqrate;
data.intdff = 1:length(data.dff);                % integral curve
data.singleTransient = zeros(1,exp_p.numpnts);   % fluorescence transient for current AP, will take ca2fluor mode into account
data.freecamodel = zeros(1,exp_p.numpnts);
data.model = zeros(1,exp_p.numpnts);
data.spiketrain = zeros(1,exp_p.numpnts);
data.slide = zeros(1,exp_p.numpnts);            % sliding curve, zero corrected
data.temp = 1:length(data.dff);                 % temporary wave
data.peel = zeros(1,exp_p.numpnts);
data.peel = data.dff;
data.spikes = zeros(1,1000);                    % array for found spikes times
data.numspikes = 0;                             % number of spikes found
[ca_p, exp_p, data] = SingleFluorTransient(ca_p, exp_p, data, ca_p.ca_genmode, 1./exp_p.acqrate);
end

function ca_p = IntegralofCaTransient(ca_p, peel_p, exp_p, data)
if strcmp(peel_p.spk_recmode, 'linDFF')
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

elseif strcmp(peel_p.spk_recmode, 'satDFF')
    startIdx = min( round(ca_p.onsetposition.*exp_p.acqrate), (length(data.singleTransient)-1) );
    stopIdx = min( round( (ca_p.onsetposition+peel_p.intcheckwin).*exp_p.acqrate), length(data.singleTransient));    
    currentTim = data.tim(startIdx:stopIdx);
    currentTransient = data.singleTransient(startIdx:stopIdx);
    ca_p.integral = trapz(currentTim,currentTransient);
    ca_p.integral = ca_p.integral * ca_p.scale;
    stopIdx = min(round( (ca_p.onsetposition+peel_p.negintwin).*exp_p.acqrate), length(data.singleTransient) );    
    currentTim = data.tim(startIdx:stopIdx);
    currentTransient = data.singleTransient(startIdx:stopIdx);
    ca_p.negintegral = trapz(currentTim,currentTransient);
    ca_p.negintegral = ca_p.negintegral * -1.0 * ca_p.scale;
else
    error('Error in CaIntegral calculation. Illdefined mode.');
end
end

function y = modelCalciumTransient(t,onsettime,onsettau,amp1,tau1)
offset = 0;
y = repmat(offset,numel(t),1);
ind = t > onsettime;
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

function [spkTout,output] = PeelingOptimizeSpikeTimes(dff,spkTin,lowerT,upperT,...
    rate,tauOn,A1,tau1,optimMethod,maxIter)
t = (1:numel(dff))./rate;
modelTransient = modelCalciumTransient(t,t(1),tauOn,A1,tau1);
modelTransient = modelTransient';
spkTout = spkTin;
spkVector = zeros(1,numel(t));
for i = 1:numel(spkTin)
    [~,idx] = min(abs(spkTin(i)-t));
    spkVector(idx) = spkVector(idx)+1;
end
model = conv(spkVector,modelTransient);
model = model(1:length(t));
residual = dff - model;
resInit = sum(residual.^2);
% start optimization
x0 = spkTin;
lbound = spkTin - lowerT;
lbound(lbound<0) = 0; %#ok<NASGU>
ubound = spkTin + upperT;
ubound(ubound>max(t)) = max(t); %#ok<NASGU>
lbound = zeros(size(spkTin));
ubound = repmat(max(t),size(spkTin));
opt_args.dff = dff;
opt_args.rate = rate;
opt_args.tauOn = tauOn;
opt_args.A1 = A1;
opt_args.tau1 = tau1;
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
options.Display = 'off';
options.MaxIter = maxIter;
options.MaxIter = Inf;
options.UseParallel = 'always';
options.ObjectiveLimit = 0;
% options.TimeLimit = 10; % in s / default is Inf
% experimental
options.MeshAccelerator = 'on'; % off by default
options.TolFun = 1e-9; % default is 1e-6
options.TolMesh = 1e-9; % default is 1e-6
options.TolX = 1e-9; % default is 1e-6
% options.MaxFunEvals = numel(spkTin)*100; % default is 2000*numberOfVariables
% options.MaxFunEvals = 20000;
options.Display = 'none';
% options.Display = 'final';
% options.PlotFcns = {@psplotbestf @psplotbestx};
% options.OutputFcns = @psoutputfcn_peel;
switch lower(optimMethod)
    case 'simulated annealing'
        [x, fval , ~, output] = simulannealbnd(...
            @(x) objectiveFuncSpkTime(x,opt_args),x0,lbound,ubound,options);
    case 'pattern search'
        [x, fval , ~, output] = patternsearch(...
            @(x) objectiveFuncSpkTime(x,opt_args),x0,[],[],[],[],lbound,...
            ubound,[],options);
    case 'genetic'
        [x, fval , ~, output] = ga(...
            @(x) objectiveFuncSpkTime(x,opt_args),numel(x0),[],[],[],[],lbound,...
            ubound,[],options);
end
if fval < resInit
    spkTout = x;
else
    disp('Optimization did not improve residual. Keeping input spike times.')
end
end

function residual = objectiveFuncSpkTime(spkTin,opt_args)
dff = opt_args.dff;
rate = opt_args.rate;
tauOn = opt_args.tauOn;
A1 = opt_args.A1;
tau1 = opt_args.tau1;
t = (1:numel(dff))./rate;
modelTransient = spkTimes2Calcium(0,tauOn,A1,tau1,0,0,rate,max(t));
spkVector = zeros(1,numel(t));
for i = 1:numel(spkTin)
    [~,idx] = min(abs(spkTin(i)-t));
    spkVector(idx) = spkVector(idx)+1;
end
model = conv(spkVector,modelTransient);
model = model(1:length(t));
residual = dff-model;
residual = sum(residual.^2);
end

function [spkTout,output] = PeelingOptimizeSpikeTimesSaturation(dff,spkTin,lowerT,upperT,...
    ca_amp,ca_gamma,ca_onsettau,ca_rest, ca_kappas, kd, conc, dffmax, frameRate, dur, optimMethod,maxIter)
spkTout = spkTin;
t = (1:numel(dff))./frameRate;
ca = spkTimes2FreeCalcium(spkTin,ca_amp,ca_gamma,ca_onsettau,ca_rest, ca_kappas,...
                                    kd, conc,frameRate,dur);
modeltmp = Calcium2Fluor(ca,ca_rest,kd,dffmax);
model = modeltmp(1:length(dff));
residual = dff - model;
resInit = sum(residual.^2);
% start optimization
x0 = spkTin;
lbound = spkTin - lowerT;
lbound(lbound<0) = 0; %#ok<NASGU>
ubound = spkTin + upperT;
ubound(ubound>max(t)) = max(t); %#ok<NASGU>
lbound = zeros(size(spkTin));
ubound = repmat(max(t),size(spkTin));
opt_args.dff = dff;
opt_args.ca_rest = ca_rest;
opt_args.ca_amp = ca_amp;
opt_args.ca_gamma = ca_gamma;
opt_args.ca_onsettau = ca_onsettau;
opt_args.ca_kappas = ca_kappas;
opt_args.kd = kd;
opt_args.conc = conc;
opt_args.dffmax = dffmax;
opt_args.frameRate = frameRate;
opt_args.dur = dur;
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
options.Display = 'off';
options.MaxIter = maxIter;
options.MaxIter = Inf;
options.UseParallel = 'always';
options.ObjectiveLimit = 0;
options.TimeLimit = 10; % in s / default is Inf
% experimental
options.MeshAccelerator = 'on'; % off by default
options.TolFun = 1e-9; % default is 1e-6
options.TolMesh = 1e-9; % default is 1e-6
options.TolX = 1e-9; % default is 1e-6
% options.MaxFunEvals = numel(spkTin)*100; % default is 2000*numberOfVariables
% options.MaxFunEvals = 20000;
options.Display = 'none';
% options.Display = 'final';
% options.PlotFcns = {@psplotbestf @psplotbestx};
% options.OutputFcns = @psoutputfcn_peel;
switch lower(optimMethod)
    case 'simulated annealing'
        [x, fval , ~, output] = simulannealbnd(...
            @(x) objectiveFuncSpkTimeSat(x,opt_args),x0,lbound,ubound,options);
    case 'pattern search'
        [x, fval , ~, output] = patternsearch(...
            @(x) objectiveFuncSpkTimeSat(x,opt_args),x0,[],[],[],[],lbound,...
            ubound,[],options);
    case 'genetic'
        [x, fval , ~, output] = ga(...
            @(x) objectiveFuncSpkTimeSat(x,opt_args),numel(x0),[],[],[],[],lbound,...
            ubound,[],options);
end
if fval < resInit
    spkTout = x;
else
    disp('Optimization did not improve residual. Keeping input spike times.')
end
end

function residual = objectiveFuncSpkTimeSat(spkTin,opt_args)
dff = opt_args.dff;
ca_rest = opt_args.ca_rest;
ca_amp = opt_args.ca_amp;
ca_gamma = opt_args.ca_gamma;
ca_onsettau = opt_args.ca_onsettau;
ca_kappas = opt_args.ca_kappas;
kd = opt_args.kd;
conc = opt_args.conc;
dffmax = opt_args.dffmax;
frameRate = opt_args.frameRate;
dur = opt_args.dur;
ca = spkTimes2FreeCalcium(sort(spkTin),ca_amp,ca_gamma,ca_onsettau,ca_rest, ca_kappas,...
                                    kd, conc,frameRate,dur);
modeltmp = Calcium2Fluor(ca,ca_rest,kd,dffmax);
model = modeltmp(1:length(dff));
residual = dff-model;
residual = sum(residual.^2);
end

function spikeTimes = PoissonSpikeTrain(rate, dur) %#ok<DEFNU>
dt = 0.0001;
spikeTimes=[];
for t=0:dt:dur
    if (rate*dt)>=rand
        spikeTimes(end+1,1)=t;
    end
end
end

function [ca_p, exp_p, data] = SingleFluorTransient(ca_p, exp_p, data, mode, starttim)
ca_p.onsetposition = starttim;
% data.singleTransient(1:end) = ca_p.offset;
if strcmp(mode, 'linDFF')
    data.singleTransient = repmat(ca_p.offset,1,numel(data.tim));
elseif strcmp(mode, 'satDFF')
    data.singleTransient = zeros(1,numel(data.tim));
end
% for n = 1:length(data.singleTransient)
%     if (data.tim(n) > ca_p.onsetposition)
%        data.singleTransient(n) = data.singleTransient(n) + ca_p.scale*(1-exp(-(data.tim(n)-ca_p.onsetposition)/ca_p.onsettau)) * ...
%            (ca_p.amp1*exp(-(data.tim(n)-ca_p.onsetposition)/ca_p.tau1)+ ca_p.amp2*exp(-(data.tim(n)-ca_p.onsetposition)/ca_p.tau2));
%     end
% end
% faster version - Felipe Gerhard
ind = data.tim >= ca_p.onsetposition; % relevant indices
firstind = find(ind, 1, 'first');
lastind = find(ind, 1, 'last');
if strcmp(mode, 'linDFF')
    data.singleTransient(ind) = ca_p.offset + ...
    ca_p.scale.*(1-exp(-(data.tim(ind)-ca_p.onsetposition)./ca_p.onsettau)) .* ...
          (ca_p.amp1.*exp(-(data.tim(ind)-ca_p.onsetposition)./ca_p.tau1)+ ...
          ca_p.amp2.*exp(-(data.tim(ind)-ca_p.onsetposition)./ca_p.tau2));
elseif strcmp(mode, 'satDFF')
    if (lastind - firstind <= 2) 
        firstind= lastind-2;  % have at least 3 points at end of trace for processing
    end
    %indoffset = round( 3.*ca_p.ca_onsettau.*exp_p.acqrate );
    if (firstind==1)
            ca_p.ca_current = Fluor2Calcium(data.dff(1),ca_p.ca_rest,exp_p.kd, exp_p.dffmax);  % set to rest when transsient at start of trace
    else
            ca_p.ca_current = Fluor2Calcium(data.dff(firstind-1),ca_p.ca_rest,exp_p.kd, exp_p.dffmax);  %calculate current, preAP Ca level
    end    
    tspan = data.tim(firstind:lastind);
    % decay from pre AP level
    Y0 = ca_p.ca_current;
    [~,lowtmp] = CalciumDecay(ca_p.ca_gamma,ca_p.ca_rest,Y0, ca_p.ca_kappas, exp_p.kd, exp_p.conc, tspan);
    lowdff = Calcium2Fluor(lowtmp,ca_p.ca_rest,exp_p.kd, exp_p.dffmax);
    % decay from post AP level
    exp_p.kappab = exp_p.kd.*exp_p.conc./(ca_p.ca_current+exp_p.kd).^2;  % recalculate kappab and ca_amp1 
    ca_p.ca_amp1=ca_p.ca_amp./(1+ca_p.ca_kappas+exp_p.kappab);
    Y0 = ca_p.ca_current + ca_p.ca_amp1;
    [~,hightmp] = CalciumDecay(ca_p.ca_gamma,ca_p.ca_rest,Y0, ca_p.ca_kappas, exp_p.kd, exp_p.conc, tspan);
    highdff = Calcium2Fluor(hightmp,ca_p.ca_rest,exp_p.kd, exp_p.dffmax);
    difftmp = highdff' - lowdff';
    caonset = (1 - exp(-(tspan-tspan(1))./ca_p.ca_onsettau));  % filter with exponential rise 
    data.singleTransient(firstind:lastind) = difftmp.*caonset;
else
    error('Undefined mode for SingleTransient generation');
end
end

function [y, x] = spkTimes2Calcium(spkT,tauOn,ampFast,tauFast,ampSlow,...
    tauSlow,frameRate,duration)
x = 0:(1/frameRate):duration;
y = (1-(exp(-(x-spkT)./tauOn))).*...
    (ampFast.*exp(-(x-spkT)./tauFast))+(ampSlow.*exp(-(x-spkT)./tauSlow)); 
% y = (1-(exp(-(x-spkT)./tauOn))).*(ampFast*exp(-(x-spkT)./tauFast));
y(x<spkT) = 0;
y(isnan(y)) = 0;
end

function [y, x] = spkTimes2FreeCalcium(spkT,Ca_amp,Ca_gamma,Ca_onsettau,Ca_rest, kappaS,...
    Kd, Conc,frameRate,duration)
x = 1/frameRate:(1/frameRate):duration;
y = zeros(1,length(x)); y(:) = Ca_rest;
unfilt = zeros(1,length(x)); unfilt(:) = Ca_rest;
for i = 1:numel(spkT)
    if i < numel(spkT)
        ind = find(x >= spkT(i), 1, 'first');
        lastind = find(x >= spkT(i+1), 1, 'first');
        if (lastind-ind) <= 2
            lastind = ind+2;  % have at least 3 points to process
        end
    else
        ind = find(x >= spkT(i), 1, 'first');
        lastind = find(x >= spkT(i), 1, 'last');
        if (lastind-ind) <= 2
            ind = lastind-2;  % have at least 3 points to process
        end
    end            
    tspan = x(ind:lastind);
    %currentCa = y(ind); 
    currentCa = unfilt(ind);    
    Y0 = currentCa;   % current ca conc following increment due to next spike
    [~,ylow] = CalciumDecay(Ca_gamma,Ca_rest,Y0, kappaS, Kd, Conc, tspan);   % solving ODE for single comp model
    kappa = Kd.*Conc./(currentCa+Kd).^2;
    Y0 = currentCa + Ca_amp./(1+kappaS+kappa);   % current ca conc following increment due to next spike
    [~,yout] = CalciumDecay(Ca_gamma,Ca_rest,Y0, kappaS, Kd, Conc, tspan);   % solving ODE for single comp model
    unfilt(ind:lastind) = yout;
    % now onset filtering with rising exponential
    % caonset = (1 - exp(-(tspan-tspan(1))./Ca_onsettau));
    caonset = (1 - exp(-(tspan-spkT(i))./Ca_onsettau));
    caonset( caonset < 0) = 0;
    difftmp = yout - ylow;
    yout = difftmp.*caonset' + ylow;
    y(ind:lastind) = yout;
end
end