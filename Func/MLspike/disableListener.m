function c = disableListener(hl)
% function c = disableListener(hl)
%---
% Disable listener(s) and return an onCleanup object that will re-enable it
% (them) upon deletion. This is particularly useful for temporarily
% disabling a listener during the time a specific function will execute,
% without worrying of error potentially hapening in this function, as the
% listener will be re-enabled in any case.
%
% See also deleteValid (and Matlab onCleanup documentation)

% Thomas Deneux
% Copyright 2015-2017

if nargout==0
    error 'function disableListener should be used with an output argument (onCleanup object), use enableListener(hl,false) to simply disable a listener'
end
disable(hl)
c = onCleanup(@()enable(hl));

function disable(hl)

if ~isvalid(hl), return, end
if fn_matlabversion('newgraphics') || isa(hl,'event.listener')
    [hl.Enabled] = deal(false);
else % property listener, previous to R2014b
    [hl.Enabled] = deal('off');
end

function enable(hl)

if ~isvalid(hl), return, end
if fn_matlabversion('newgraphics') || isa(hl,'event.listener')
    [hl.Enabled] = deal(true);
else % property listener, previous to R2014b
    [hl.Enabled] = deal('on');
end
