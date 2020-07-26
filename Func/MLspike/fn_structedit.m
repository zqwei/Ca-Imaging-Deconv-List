function s = fn_structedit(s,varargin)
% function s = fn_structedit(s[,spec][,hp][,other fn_control arguments...])
% function s = fn_structedit(fieldname1,value1,fieldname2,value2,...)
%---
% allow user to interactively modify a structure, and returns the modified
% structure; returns an empty array if the figure is closed
% this function is a wrapping of fn_control
% 
% See all fn_control, fn_input, fn_reallydlg

% Thomas Deneux
% Copyright 2007-2017

if ischar(s)
    % build a 3-elements structure
    structdef = [s varargin];
    for k=2:2:length(structdef)
        a = structdef{k};
        if iscell(a)
            [a{end+1:3}] = deal([]);
        else
            a = {a [] []}; %#ok<AGROW>
        end
        structdef{k} = a;
    end
    s = struct(structdef{:});
    varargin = {};
end
X = fn_control(s,varargin{:},'ok');
addlistener(X,'OK',@(u,e)update());
update()
% wait that the figure will be destroyed
s = [];
waitfor(X.hp)
drawnow % otherwise figure will stay on if heavy computation continue afterwards

% nested function: update of s
function update
    s = X.s;
end

end
        
        

