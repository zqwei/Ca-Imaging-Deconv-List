function y = fn_timevector(x,t,outputtype)
% function times|count = fn_timevector(times|count,dt|tidx[,outputtype])
%---
% switch representation of a point process between the times of the events
% and the number of events per time bin
%
% Input:
% - count       vector of spike count at each time bin (or array or cell
%               array of vectors)
% - times       vector of spike times (or cell array thereof)
% - dt          scalar - size of time bin
% - tidx        vector of all time instants
% - outputtype  'times', 'rate' or 'count' [default: output type is the
%               opposite of input type]; use 'rateperperiod' or
%               'countperperiod' to count using time bins that are not
%               centered on the time points in tidx, but rather whose sides
%               are defined by the time points in tidx (which can be either
%               a (nperiod+1) vector for contiguous periods, or a 2*nperiod
%               array for disconnected periods)
%
% Output:
% - count       column vector or array
% - times       row vector or cell array of row vectors

% Thomas Deneux
% Copyright 2010-2017

if nargin==0, help fn_timevector, return, end

% Convert matrix to cell array
xisarray = ~iscell(x) && all(size(x)>1);
if xisarray, x = squeeze(num2cell(x,1)); end % matrix -> cell array of column vectors

% Input type
if xisarray
    inputtype = 'count';
else
    if iscell(x), xtest=x{1}; else xtest=x; end
    if any(isnan(xtest))
        inputtype = 'count';
    elseif all(xtest) || any(mod(xtest,1)) || length(xtest)<10 || ~any(xtest==0)
        inputtype = 'times';
    else
        inputtype = 'count';
    end
end

% Output type
if nargin<3
    outputtype = fn_switch(inputtype,'times','count','count','times');
elseif ~ismember(outputtype,{'times' 'count' 'rate' 'countperperiod' 'rateperperiod'})
    error('output type must be either ''times'', ''count'' or ''countperperiod''')
end
doperiod = any(strfind(outputtype,'perperiod'));
dorate   = any(strfind(outputtype,'rate'));

% Multiple data
if iscell(x)
    nx = numel(x);
    if numel(t)==nx
        % time definitions are different for each sample
        t = num2cell(t);
    else
        t = repmat({t},1,nx);
    end
    y = cell(1,nx);
    for i=1:nx
        y{i} = fn_timevector(x{i},t{i},outputtype); 
    end
    if ~strcmp(outputtype,'times')
        nper = fn_itemlengths(y); % not all counts are necessarily the same time: pad with zeros
        if any(diff(nper))
            npermax = max(nper);
            for i=1:nx, y{i}(end+1:npermax,1)=0; end
        end
        nper = max(nper);
        if isvector(x)
            y = reshape(cat(1,y{:}),[nper length(x)]);
        else
            y = reshape(cat(1,y{:}),[nper size(x)]);
        end
    end
    return
end

% Conversion type
if ~strcmp(outputtype,'times'), outputtype = 'count'; end
convtype = [inputtype(1) '2' fn_switch(outputtype,'times','t','c')];
if doperiod && strcmp(inputtype,'count'), error('cannot count per period if input is already a count'), end

% Time specification
if isscalar(t)
    if doperiod
        error('when counting events inside defined periods, the time periods must be defined by a vector of time instants')
    end
    dt = t;
    t0 = 0;
    iseqspacing = true;
    if strcmp(inputtype,'times')
        nper = ceil(max(fn_map(@row,x,'array')-t0)/dt);
        if isempty(nper), nper = 0; end
    else
        nper = length(x);
    end
    if strcmp(convtype,'c2t') && nper==0
        error('times to count conversion: number of time instants unknown, please provide time information as the vector of time instants')
    end
else
    if ~strcmp(convtype,'t2c')
        error 'time specification should be a scalar for this conversion type'
    end
    if doperiod
        % disconnected periods can be supplied as a (2 x nper) array of
        % time points
        isperiodsconnex = isvector(t);
        if isperiodsconnex
            tidx = t;
            periods = [t(1:end-1); t(2:end)];
        else
            if size(t,1)~=2, error('wrong format for periods'); end
            periods = t;
            % not defining any tidx
        end
        nper = size(periods,2);
    else
        tidx = t;
        if ~isvector(tidx), error('vector of time instants is not a vector!'), end
        nper = length(tidx);
    end
    if ~doperiod || isperiodsconnex
        % tidx is defined: check whether time points are equally spaced
        iseqspacing = diff(tidx(1:2))>0 && all(abs(diff(tidx,2))<100*eps(tidx(end)));
        if ~doperiod && ~iseqspacing, error('time points are not equally spaced'), end
        if iseqspacing
            dt = (tidx(end)-tidx(1))/(length(tidx)-1);
            if doperiod, t0 = tidx(1)+dt/2; else t0 = tidx(1); end
        end
    else
        iseqspacing = false;
    end
end

% Conversion
switch convtype
    case 't2t'
        y = x(:)';
    case 'c2c'
        y = x(:);
    case 't2c'
        times = x(:);
        y = zeros(nper,1);
        if (~doperiod || isperiodsconnex) && (iseqspacing || length(times)<2*length(tidx))
            if iseqspacing
                % take advantage of the fact that time instants are equally spaced
                kper = 1+round((times-t0)/dt);
                kper(kper<1 | kper>nper) = [];
                for i=1:length(kper), y(kper(i)) = y(kper(i))+1; end
            else
                % find 'manually' to which bin belongs each event
                for i=1:length(times)
                    kper = find(times(i)>=tidx,1,'last');
                    if isempty(kper) || kper>nper, continue, end
                    y(kper) = y(kper)+1;
                end
            end
        else
            % find 'manually' which events belong to each period
            for kper=1:nper
                y(kper) = sum(times>=periods(1,kper) & times<periods(2,kper));
            end
        end
    case 'c2t'
        count = x(:);
        if any(isnan(count)), y = []; return, end
        if islogical(count), count = uint8(count); end
        times = zeros(1,sum(count));
        idx = 0;
        for i=find(count)'
            ci = double(count(i));
            times(idx+(1:ci)) = t0+(i-1)*dt;
            idx = idx+ci;
        end
        y = times;
end

% Convert count to rate
if dorate
    if iseqspacing
        y = y / dt;
    else
        for kper=1:nper
            y(kper) = y(kper) / diff(periods(:,kper));
        end
    end
end



