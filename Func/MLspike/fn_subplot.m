function ha = fn_subplot(varargin)
% function ha = fn_subplot([hf,]nrow,ncol,k[,spacing])
% function ha = fn_subplot([hf,]ngraph,k) % hf must be an object figure handle here
% function ha = fn_subplot(hnnk|hnk|nnk|nk)
%---
% if only 3 arguments, nrow and ncol are guessed from ngraphs

% Thomas Deneux
% Copyright 2008-2017

% input
if nargin==1
    abcd = str2num(num2str(varargin{1})'); %#ok<ST2NM>
    if ismember(length(abcd),[2 3 4])
        varargin = num2cell(abcd);
    else
        error argument
    end
end
if mod(varargin{end},1)
    spacing = varargin{end}; varargin(end) = [];
else
    spacing = 0;
end
if isobject(varargin{1}) || length(varargin)>3
    hf = varargin{1}; varargin(1) = [];
    if ~ishandle(hf), figure(hf), end
else
    hf = gcf;
end
switch length(varargin)
    case 2
        [ngraph kk] = deal(varargin{:});
        ncol = ceil(sqrt(ngraph));
        nrow = ceil(ngraph/ncol);
    case 3
        [nrow ncol kk] = deal(varargin{:});
    otherwise
        error arguments
end

% delete annoying axes
info = getappdata(hf,'fn_subplot');
if isempty(info) || info.ncol~=ncol || info.nrow~=nrow
    delete(findobj(hf,'parent',hf,'type','axes')); 
    info = struct('ncol',ncol,'nrow',nrow,'axes',zeros(ncol,nrow));
end

% create new axis or find existing one
ha = zeros(1,length(kk));
for ik=1:length(kk)
    k = kk(ik);
    if info.axes(k) && info.ncol==ncol && info.nrow==nrow && ishandle(info.axes(k))
        ha(ik) = info.axes(k);
    else
        icol = 1+mod(k-1,ncol);
        irow = 1+floor((k-1)/ncol);
        pos = [(icol-1+spacing/2)/ncol (nrow-irow+spacing/2)/nrow (1-spacing)/ncol (1-spacing)/nrow];
        ha(ik) = axes('parent',hf,'units','normalized','pos',pos);
        info.axes(k) = ha(ik);
    end
end
setappdata(hf,'fn_subplot',info)

% output
if nargout==0
    axes(ha)
    clear ha
end
    