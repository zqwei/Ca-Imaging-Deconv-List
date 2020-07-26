function answer = fn_dialog_questandmem(question,identifier)
% function answer = fn_dialog_questandmem(question[,identifier])
%---
% This imitates Windows style confirmation window, with a choice between
% 'Yes' and 'Cancel', and additionally a possibility to mark a box 'Do not
% ask again'.
%
% Input:
% - question        string - the question
% - identifier      string - a unique identifier that serves to store the
%                   choice not to ask again the question [default: the
%                   question is used as an identifier]
%
% Output:
% - answer          logical - true for 'Yes', false for 'Cancel'
%
% See also fn_reallydlg

% Thomas Deneux
% Copyright 2010-2017

if nargin==0, help fn_dialog_questandmem, return, end

persistent memkeep
if ~iscell(memkeep), memkeep = {}; end

% Input
if nargin<2, identifier=question; end

% Answer already in memory?
if fn_ismemberstr(identifier,memkeep)
    answer = true;
    return
end

% Dimensions
ax = 10;
aw = 120;
ay = 10;
ah = 20;

bw = 60;
bd = 10;
by = 10;
bh = 20;

ix = 10;
iy = 50;
iw = 54;
ih = 54;

qx = 70;
qw = 200;
qy = by+bh+10;
qh = 50;

bx = (qx+qw)-(bw+bd+bw);

W = max(bx+bw+bd+bw,qx+qw)+10;
H = max(iy+ih,qy+qh)+10;

% Figure
hf = dialog;
p = get(0,'pointerLocation');
desiredpointerpos = [bx+bw+bd+bw/2 by+bh/2];
set(hf,'pos',[p-desiredpointerpos W H])
movegui(hf)

% Icon
IconAxes=axes(                                      ...
  'Parent'      ,hf              , ...
  'Units'       ,'Pixels'              , ...
  'Position'    ,[ix iy iw ih], ...
  'NextPlot'    ,'replace'             , ...
  'Tag'         ,'IconAxes'              ...
  );
set(hf ,'NextPlot','add');
load dialogicons.mat questIconData questIconMap;
IconData=questIconData;
questIconMap(256,:)=get(hf,'Color');
Img=image('CData',IconData,'Parent',IconAxes);
set(hf, 'Colormap', questIconMap);
set(IconAxes, ...
  'Visible','off'           , ...
  'YDir'   ,'reverse'       , ...
  'XLim'   ,get(Img,'XData'), ...
  'YLim'   ,get(Img,'YData')  ...
  );

% Question
uicontrol(hf,'style','text','backgroundcolor',get(hf,'color'),'string',question, ...
    'pos',[qx qy qw qh])

% Yes/No buttons
uyes = uicontrol(hf,'string','Yes','pos',[bx by bw bh],'Callback','uiresume(gcf)');
uicontrol(hf,'string','Cancel','pos',[bx+bw+bd by bw bh],'Callback','uiresume(gcf)');

% 'Do not ask again' button
umem = uicontrol(hf,'style','checkbox','string','Always Yes', ...
    'pos',[ax ay aw ah],'parent',hf);

% Answer
uiwait(hf)
if ishandle(hf)
    answer = (get(hf,'currentobject')==uyes);
    mem = answer && logical(get(umem,'value'));
    close(hf)
else 
    mem = false;
    answer = false;
end

% Keep 'Yes' in memory if required
if mem
    memkeep{end+1} = identifier;
end
    
