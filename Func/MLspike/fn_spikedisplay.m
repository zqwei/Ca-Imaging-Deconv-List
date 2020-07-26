function [hl y] = fn_spikedisplay(times,varargin)
% function hl = fn_spikedisplay(times[,ypos][,spikeheight [spikewidth]][,'numbers'],plot options...)
% function hl = fn_spikedisplay(times,[ymin; ymax][,spikewidth][,'numbers'],plot options...)
%---
% this function display spikes as small bars, it is a simple wrapper of
% Matlab line function
% 
% Input:
% - times       vector of time points (or cell array of length n)
% - ypos        scalar (or n-elements vector) - vertical position of spikes
% - spikeheight scalar - if spikes height is not specified, markers are
%               used rather than small vertical bars; if height is set to
%               zero, an automatic height is calculated
% - spikewidth  scalar - controls the spike width in time units
% - 'numbers'   option to print numbers below spikes that are covering each
%               other; to know if it is the case, the line width is used,
%               multiplied by a factor; the default value of this factor is
%               1.3, and can be changed, e.g. by specifying 'numbers1.2'
% - plot options...     same options as for line function
%
% Output:
% - hl      handle of line(s)
%
% See also fn_rasterplot

% Thomas Deneux
% Copyright 2012-2017

if nargin==0, help fn_spikedisplay, return, end

% input
if ~iscell(times)
    times = {times};
end
n = numel(times);
y = []; spikeheight = []; spikewidth = []; donumbers = false;
plotopts = {};
for karg=1:length(varargin)
    a = varargin{karg};
    if ischar(a)
        if strfind(a,'numbers')
            donumbers = true;
            numberfactor = sscanf(a,'numbers%f');
            if isempty(numberfactor), numberfactor = 1.3; end
        else
            plotopts = varargin(karg:end);
            break
        end
    elseif isempty(y) && ~(n>1 && isscalar(a))
        y = a;
        if (numel(y)==2 && n~=2) || (size(y,1)==2 && size(times,1)~=2)
            spikeheight = mean(diff(y));
            if spikeheight==0, spikeheight=[]; end
            y = mean(y);
        end
        if numel(y)~=n
            error argument
        end
    elseif isempty(spikeheight)
        spikeheight = a(1);
        if ~isscalar(a), spikewidth = a(2); end
    elseif isempty(spikewidth)
        spikewidth = a;
    else
        error argument
    end
end

% special: auto-pos
if isempty(y)
    if ~isvector(times)
        [n1 n2] = size(times); 
        y = fn_add(-.4+(0:n1-1)'/n1*.7,1:n2);
        if isempty(spikeheight), spikeheight = .6/n1*.7; end
    else
        y = (1:n)';
        if isempty(spikeheight), spikeheight = .6; end
    end
else
    if isvector(times)
        y = y(:);
    else
        y = reshape(y,size(times));
    end
end

% display
if ~isempty(spikeheight)
    % display spikes
    if spikeheight==0
        if n==1, spikeheight=1; else spikeheight = mean(diff(y))*.6; end
    end
    y1 = [y(:)'-spikeheight/2; y(:)'+spikeheight/2];
    hl = zeros(size(times));
    for k=1:n
        spk = times{k}(:)';
        if isempty(spk), continue, end
        nspk = length(spk);
        xdata = [spk; spk; nan(1,nspk)];
        ydata = repmat([y1(:,k); NaN],1,nspk);
        hl(k) = line(xdata(:),ydata(:),plotopts{:});
    end
else
    hl = zeros(size(times));
    for k=1:n
        spk = times{k}(:)';
        if isempty(spk), continue, end
        xdata = spk;
        ydata = y(k)*ones(1,length(xdata));
        hl(k) = line(xdata,ydata,'linestyle','none','marker','*',plotopts{:});
    end
end

% spike width
if ~isempty(spikewidth) || donumbers
    kparent = find(strcmpi(plotopts,'parent'));
    if isempty(kparent)
        ha = gca;
    else
        ha = plotopts{kparent+1};
    end
end
if ~isempty(spikewidth)
    pixwidth = fn_coordinates(ha,'a2b',[spikewidth 0],'vector');
    pixwidth = pixwidth(1);
    hlok = hl(hl~=0);
    set(hlok,'linewidth',pixwidth)
elseif donumbers 
    klinewidth = find(strcmpi(plotopts,'linewidth'));
    if isempty(klinewidth)
        pixwidth = get(ha,'defaultlinelinewidth');
    else
        pixwidth = plotopts{klinewidth+1};
    end
    kcolor = find(strcmpi(plotopts,'color'));
    if isempty(kcolor)
        col = get(ha,'defaultlinecolor');
    else
        col = plotopts{kcolor+1};
    end
    spikewidth = fn_coordinates(ha,'b2a',[pixwidth 0],'vector');
    spikewidth = spikewidth(1);
end

% numbers
if donumbers
    for k=1:n
        spk = times{k}(:)';
        if isempty(spk), continue, end
        % auto-detect burst
        delays = diff(spk);
        kglued = find(delays<spikewidth*numberfactor);
        gaps = [0 find(diff(kglued)>1) length(kglued)];
        ngroup = length(gaps)-1;
        groupbeg = kglued(gaps(1:ngroup)+1);
        groupend = kglued(gaps(2:ngroup+1))+1;
        npergroup = groupend+1-groupbeg;
        % display
        for i=1:ngroup
            xi = (spk(groupbeg(i))+spk(groupend(i)))/2;
            text(xi,y(k)-spikeheight,num2str(npergroup(i)), ...
                'horizontalalignment','center','verticalalignment','top','color',col)
        end
    end
end

% % improve axis
% if ~isempty(hl)
%     ha = get(hl(1),'parent');
%     ax = axis(ha);
%     ax1 = ax;
%     if ax(3)==min(y(:)), ax1(3) = min(y(:))-diff(ax(3:4))/20; end
%     if ax(4)==max(y(:)), ax1(4) = max(y(:))+diff(ax(3:4))/20; end
%     if ~all(ax1==ax), axis(ha,ax1), end
% end

% output
if nargout==0, clear hl, end

