function c = fn_watch(hf,varargin)
% function c = fn_watch([hf])

% Thomas Deneux
% Copyright 2012-2012

% disp 'fn_watch has a bug, skip it'
% c = [];
% return


if nargin==0, hf = gcf; end

if nargout==0
    % Old syntax, does not use an onClean object and requires manual
    % stopping
    if fn_dodebug, warning 'syntax for fn_watch function has changed!', end
    if nargin<2 || ismember(varargin{1},{'start' 'startnow'})
        startfcn(hf)
    elseif strcmp(varargin{1},'stop')
        stopfcn(hf,[],'arrow')
    else
        error 'argument'
    end
    return
end

curpointer = get(hf,'Pointer');
if eval('true')
    t = maketimer(hf);
    if strcmp(get(t,'Running'),'on')
        c = [];
        return
    end % timer already started
    start(t)
else
    startfcn(hf)
    t = [];
end
c = onCleanup(@()stopfcn(hf,t,curpointer));

function t = maketimer(hf)

% timer is stored in figure to avoid loosing time creating it multiple
% times
t = getappdata(hf,'fn_watch_timer');
if isempty(t)
    t = timer('StartDelay',.5,'TimerFcn',@(u,e)startfcn(hf));
    setappdata(hf,'fn_watch_timer',t)
    fn_deletefcn(hf,@(u,e)delete(t));
end

function startfcn(hf)

set(hf,'Pointer','watch')
drawnow

function stopfcn(hf,t,curpointer)

if ~isempty(t), stop(t), end
set(hf,'Pointer',curpointer)


