function hl = fn_plotscale(varargin)
% function hl = fn_plotscale([ha,]tlabel,ylabel[,t_y_sizes[,posflag]])
%---
% Creates a 2 directional scale bar for graph display
%
% Input:
% - tlabel      string with %f%s format, for example '1s'
% - ylabel      string with %f%s format, for example '10mV'
% - posflag     'extend' [default], 'top', 'bottom', 'center', or
%               coordinates, or one of the string flag followed by
%               coordinates (indicating a translation)
%
% See also fn_scale

% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_plotscale, return, end
    

posflag = '';
tysize = []; dotranslate = false;
if ishandle(varargin{1})
    ha = varargin{1}; varargin(1)=[];
else
    ha = gca;
end
[tlabel ylabel] = deal(varargin{1:2}); varargin(1:2)=[];
for i=1:length(varargin)
    a = varargin{i};
    if ischar(a)
        posflag = a;
    elseif isscalar(a)
        posflag = fn_switch(a,'extend','center');
    elseif isempty(tysize) && isempty(posflag)
        tysize = a;
    elseif isempty(posflag)
        posflag = 'user';
        posuser = a;
    else
        dotranslate = true;
        posuser = a;
    end
end
if isempty(posflag), posflag = 'extend'; end

set(ha,'visible','off')
delete(findobj(ha,'tag','fn_plotscale'))

if isempty(tysize)
    if isempty(tlabel)
        tsize=0; 
    else
        tokens = regexp(tlabel,'^([.0-9]*|auto)','tokens');
        if isempty(tokens), tokens = {'1' ''}; else tokens = tokens{1}; end
        if strcmp(tokens{1},'auto')
            [tsize str] = autoScaleLength(ha,'x');
            tlabel = strrep(tlabel,'auto',str);
        else
            tsize = str2double(tokens{1});
        end
    end
    if isempty(ylabel)
        ysize=0; 
    else
        tokens = regexp(ylabel,'^([.0-9]*(\.[0-9]*){0,1}(e-{0,1}[0-9]+){0,1}|auto)(%{0,1})','tokens');
        if isempty(tokens), tokens = {'1' ''}; else tokens = tokens{1}; end
        if strcmp(tokens{1},'auto')
            if strcmp(tokens{2},'%')
                [ysize str] = autoScaleLength(ha,'y',100);
            else
                [ysize str] = autoScaleLength(ha,'y');
            end
            ylabel = strrep(ylabel,'auto',str);
        else
            ysize = str2double(tokens{1});
            if strcmp(tokens{2},'%'), ysize = ysize/100; end
        end
    end
else
    tsize = tysize(1);
    ysize = tysize(2);
end

% scale in the bottom left
[w h] = fn_pixelsize(ha);
ax = axis(ha);
fact = [diff(ax(1:2))/w diff(ax(3:4))/h]; % axes size of one pixel
switch posflag
    case 'extend'
        ax = [ax(1) ax(2) ax(3)-ysize-15*fact(2) ax(4)];
        axis(ha,ax)
        orig = ax([1 3])+10*fact;
    case 'center'
        orig = [mean(ax(1:2)) mean(ax(3:4))];
    case {'top' 'left' 'topleft'}
        orig = [ax(1)+10*fact(1) ax(4)-10*fact(2)-ysize];
    case {'bottom' 'bottomleft'}
        orig = ax([1 3])+10*fact;
    case {'right' 'topright'}
        orig = [ax(2)-10*fact(1)-tsize ax(4)-10*fact(2)-ysize];
    case 'bottomright'
        orig = [ax(2)-10*fact(1)-tsize ax(4)-10*fact(2)];
    case 'user'
        orig = posuser;
    otherwise
        error('unknown position flag ''%s''',posflag)
end
if dotranslate, orig = orig+posuser; end

% % scale in the left and vertically centered
% axis([ax(1)-2*tsize ax(2) ax(3) ax(4)])
% ax = axis; fact = [ax(2)/(posa(3)*posf(3)) ax(4)/(posa(4)*posf(4))];
% orig = [ax(1) (ax(3)+ax(4)-ysize)/2]+fact;

if tsize~=0
    hl(1,1) = line(orig(1)+[0 tsize],orig(2)+[0 0],'color','black','linewidth',2, ...
        'tag','fn_plotscale','parent',ha);
    hl(1,2) = text(double(orig(1)+tsize/2),double(orig(2)-2*fact(2)),tlabel, ...
        'horizontalalignment','center','verticalalignment','top', ...
        'tag','fn_plotscale','parent',ha);
end
if ysize~=0
    hl(2,1) = line(orig(1)+[0 0],orig(2)+[0 ysize],'color','black','linewidth',2, ...
        'tag','fn_plotscale','parent',ha);
    hl(2,2) = text(double(orig(1)-2*fact(1)),double(orig(2)+ysize/2),ylabel, ...
        'horizontalalignment','right','verticalalignment','middle', ...
        'tag','fn_plotscale','parent',ha);
end

if nargout==0, clear hl, end

%---
function [sz label] = autoScaleLength(ha,flag,factor)

axsz = fn_pixelsize(ha);
switch flag
    case 'x'
        target = 0.15 * diff(get(ha,'xlim'))*(min(axsz)/axsz(1));
    case 'y'
        target = 0.15 * diff(get(ha,'ylim'))*(min(axsz)/axsz(2));
end
leads = [1 2 5];                        % possible leading number
dlog = log10(target./leads);             % corresponding exponent
[~, idx] = min(abs(dlog-round(dlog)));  % which one is closer to an integer
sz = leads(idx)*10.^round(dlog(idx));

if nargin<3, factor = 1; end
label = num2str(sz*factor);


