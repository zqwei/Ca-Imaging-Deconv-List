function el = fn_pixelposlistener(source,varargin)
% function el = fn_pixelposlistener(source,[target,],callback)
%---
% Add a listener that will execute whenever the pixel position of an object
% is changed. 
% In Matlab version R2014b and later, this just adds a listener to the
% object 'LocationChanged' event. In earlier versions, this is a wrapper
% for pixelposwatcher class.
%
% See also fn_pixelpos, fn_pixelsizelistener

% Thomas Deneux
% Copyright 2015-2017

% Input
switch nargin
    case 2
        callback = varargin{1};
        target = [];
    case 3
        [target callback] = deal(varargin{:});
end

% Create listener
if fn_matlabversion('newgraphics')
    el = [connectlistener(source,target,'LocationChanged',callback) connectlistener(source,target,'SizeChanged',callback)];
else
    ppw = pixelposwatcher(source);
    el = connectlistener(ppw,target,'changepos',callback);
end

% Output?
if nargout==0, clear el, end
