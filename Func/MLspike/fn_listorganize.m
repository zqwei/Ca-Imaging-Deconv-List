function [s anychg] = fn_listorganize(s,namefield,addfun)
% function [list anychg] = fn_listorganize(list)
% function [struct anychg] = fn_listorganize(struct,namefield,addfun)
%---
% Input:
% - list        list of strings
% - struct      structure
% - namefield   field in the structure containing the names to be displayed
%               as a list
% - addfun      function to execute when the 'add' button is pressed, with 
%               prototype: structitem = addfun()

% Thomas Deneux
% Copyright 2015-2017

% input
simplelist = iscell(s);
if simplelist
    s = struct('name',s);
    namefield = 'name';
    addfun = @simpleadd;
end
s_orig = s; % keep a copy, in case window is closed and changes are canceled
N = length(s);

% create dialog
hf = dialog('resize','on');
fn_setfigsize(hf,300,400)

% size
W = 80; D = 15; H = 25;

% list display
ulist = uicontrol('style','list','parent',hf, ...
    'string',{s.(namefield)},'max',2,'value',[]);
fn_controlpositions(ulist,hf,[0 0 1 1],[0 0 -(D+W+D) 0])

% buttons
u = uicontrol('string','move to top','parent',hf,'callback',@(u,e)action('movetop'));
fn_controlpositions(u,hf,[1 1 0 0],[-(W+D) -2*H W H])
u = uicontrol('string','move up','parent',hf,'callback',@(u,e)action('moveup'));
fn_controlpositions(u,hf,[1 1 0 0],[-(W+D) -3*H W H])
u = uicontrol('string','move down','parent',hf,'callback',@(u,e)action('movedown'));
fn_controlpositions(u,hf,[1 1 0 0],[-(W+D) -4*H W H])
u = uicontrol('string','move to bottom','parent',hf,'callback',@(u,e)action('movebottom'));
fn_controlpositions(u,hf,[1 1 0 0],[-(W+D) -5*H W H])

u = uicontrol('string','add...','parent',hf,'callback',@(u,e)action('add'));
fn_controlpositions(u,hf,[1 1 0 0],[-(W+D) -7*H W H])
u = uicontrol('string','delete','parent',hf,'callback',@(u,e)action('remove'));
fn_controlpositions(u,hf,[1 1 0 0],[-(W+D) -8*H W H])

ok = uicontrol('string','OK','parent',hf,'callback',@(u,e)delete(u));
fn_controlpositions(ok,hf,[1 0 0 0],[-(W+D) H W H])

anychg = false;
waitfor(ok)
if ishandle(hf)
    delete(hf)
else
    s = s_orig;
    anychg = false;
end
if simplelist
    s = {s.name};
end

    function action(flag)
        sel = get(ulist,'value');
        if regexp(flag,'^move')
            unsel = setdiff(1:N,sel);
            switch flag
                case 'movetop'
                    selnew = 1:length(sel);
                case 'movebottom'
                    selnew = N-length(sel)+1:N;
                case 'moveup'
                    selnew = max(1:length(sel),sel-1);
                case 'movedown'
                    selnew = min(N-length(sel)+1:N,sel+1);
            end
            unselnew = setdiff(1:N,selnew);
            ord = zeros(1,N);
            ord(selnew) = sel;
            ord(unselnew) = unsel;
            s = s(ord);
            set(ulist,'string',{s.name},'value',selnew)
        elseif strcmp(flag,'add')
            N = N+1;
            newitem = addfun();
            if isempty(newitem), return, end
            if simplelist
                s(N).name = newitem;
            else
                s(N) = newitem;
            end
            set(ulist,'string',{s.name},'value',N)
        elseif strcmp(flag,'remove')
            s(sel) = [];
            set(ulist,'string',{s.name},'value',[])
        end
        anychg = true;
    end

    function name = simpleadd
        answer = inputdlg('Name for new entry','',1,{''});
        if isempty(answer), name = []; else name = answer{1}; end
    end

end
