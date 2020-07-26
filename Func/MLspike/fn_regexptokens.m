function varargout = fn_regexptokens(a,expr)
% function tokens = fn_regexptokens(a,expr)
% function [tok1 ... tokn] = fn_regexptokens(a,expr)
%---
% a wrapper of regexp that returns the tokens in a string where expression
% 'expr' is assumed to occur only zero or one time
% returns the unique token if there is only one, or a cell array of tokens
% if there are several

% Thomas Deneux
% Copyright 2015-2017

tokens = regexp(a,expr,'tokens');
while iscell(tokens) && isscalar(tokens), tokens = tokens{1}; end
if nargout<=1
    varargout = {tokens};
else
    if nargout~=length(tokens), error 'number of outputs does not match number of tokens', end
    varargout = tokens;
end
