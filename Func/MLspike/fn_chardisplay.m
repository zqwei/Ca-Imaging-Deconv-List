function [out errormsg] = fn_chardisplay(varargin)
% function [str errormsg] = fn_chardisplay(val)
% function val = fn_chardisplay(str,type)
%---
% build a string representation of a non-character value and converts back
% the string to the original type
% 
% Example:
% 

% Thomas Deneux
% Copyright 2013-2017

if nargin==0, help fn_chardisplay, return, end

errormsg = '';
if nargin==1
    % conversion anything -> character
    val = varargin{1};
    if ischar(val)
        str = val;
    elseif isnumeric(val)
        if ~islogical(val) && size(val,1)==1 && all(val>=0 & mod(val,1)==0) && all(diff(val)>0)
            % vector of increasing non-negative integers: try to arrange them smartly
            str = fn_idx2str(val);
        elseif ndims(val)<=2 && numel(val)<=22
            str = num2str(val);
            str(:,end+1) = ';'; str(:,end+1) = ' ';
            str = reshape(str',1,numel(str));
            str(end-1:end) = [];
            str = regexprep(str,' *',' ');
        else
            str = [];
            errormsg = 'cannot display array with more than 2 dimensions or 22 elements';
        end
    else
        str = [];
        errormsg = sprintf('class ''%s'' cannot be represented has a string',class(val));
    end
    out = str;
elseif nargin==2
    % conversion charachter -> specified type
    str = varargin{1};
    type = varargin{2};
    switch type
        case 'char'
            val = str;
        case {'logical' 'double' 'single' 'int8' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
            try
                val = eval(['[' str ']']);
                val = cast(val,type);
            catch %#ok<CTCH>
                errormsg = 'string could not be evaluated';
            end
        otherwise
            errormsg = 'a string cannot be converted to class ''%s''';
    end
    out = val;
else
    error argument
end

if ~isempty(errormsg) && nargout<2
    error(errormsg)
end
