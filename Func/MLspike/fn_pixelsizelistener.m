function el = fn_pixelsizelistener(source,varargin)
% function el = fn_pixelsizelistener(source,[target,],callback)
%---
% Add a listener that will execute whenever the pixel size of an object
% is changed.
% In Matlab version R2014b and later, this just adds a listener to the
% object 'SizeChanged' event. In earlier versions, this is a wrapper
% for pixelposwatcher class.
%
% See also fn_pixelsize, fn_pixelposlistener

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
    el = connectlistener(source,target,'SizeChanged',callback);
else
    ppw = pixelposwatcher(source);
    el = connectlistener(ppw,target,'changesize',callback);
end

% Output?
if nargout==0, clear el, end
