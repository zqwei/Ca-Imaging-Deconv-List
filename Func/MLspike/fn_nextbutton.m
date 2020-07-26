function fn_nextbutton(resetskipflag)
% function fn_nextbutton(['resetskip'])
%---
% prompt user for a button press
% there are 2 buttons: 'NEXT' and 'SKIP'
% the function returns when button 'NEXT' is pressed
% if 'SKIP' is pressed, it will return immediately at next function calls,
% unless argument 'resetskip' is used

% Thomas Deneux
% Copyright 2015-2017

persistent m u

% Create menu
if isempty(m) || ~ishandle(m)
    [m u] = fn_menu( ...
        'add', ...
        'style','togglebutton','string','NEXT', ...
        'add', ...
        'style','togglebutton','string','SKIP');
end

% Reset 'SKIP'
doresetskip = (nargin>=1) && strcmpi(resetskipflag,'resetskip');
if doresetskip, set(u(2),'value',0); end

% Wait for button press
if ~get(u(2),'value')
    waitfor(u(1),'value',1)
    if ishandle(m), set(u(1),'value',0), end
end
