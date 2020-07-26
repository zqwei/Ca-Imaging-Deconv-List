function lineoptions = fn_linespecs(varargin)
% function lineoptions = fn_linespecs(line options as in plot)
% function lineoptions = fn_linespecs({line options as in plot})
%---
% If necessary, converts the first argument into the accurate set of line
% properties {Propertyname1,Value1,...} according to the same syntax as
% the plot command.
% This can be used to set line properties more easily.
% ex: opt=fn_linespecs('r:','linewidth',2);
%     line([0 1],[0 1],opt{:})
% 
%          b     blue          .     point              -     solid
%          g     green         o     circle             :     dotted
%          r     red           x     x-mark             -.    dashdot 
%          c     cyan          +     plus               --    dashed   
%          m     magenta       *     star             (none)  no line
%          y     yellow        s     square
%          k     black         d     diamond
%          w     white         v     triangle (down)
%                              ^     triangle (up)
%                              <     triangle (left)
%                              >     triangle (right)
%                              p     pentagram
%                              h     hexagram

% Thomas Deneux
% Copyright 2004-2017

if mod(nargin,2)==1
    flag = varargin{1};
    options = {};
    marker = false; linestyle = false;
    if isempty(flag)
        options={'LineStyle','none'}; 
    end
    k=1;
    while k<=length(flag)
        f = flag(k); k = k+1;
        if f=='-'
            if k>length(flag), error('bad line option'), end
            f=[f flag(k)]; k = k+1; 
        end
        if ismember(f,'bgrcmykw')
            propertyname = 'Color';
        elseif ismember(f,'.ox+*sdv^<>ph')
            propertyname = 'Marker';
            marker = true;
        elseif fn_ismemberstr(f,{'-',':','-.','--'})
            propertyname = 'LineStyle';
            linestyle = true;
        else
            error('bad line option')
        end
        options = [options {propertyname,f}];
    end
    if marker && ~linestyle
        % if Marker property has been set but not LineStyle property
        options = [options {'LineStyle','none'}];
    end
    lineoptions = [options varargin{2:end}];
else
    lineoptions = varargin;

end