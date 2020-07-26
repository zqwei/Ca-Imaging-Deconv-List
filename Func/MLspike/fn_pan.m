function fn_pan(ha,mode)
% function fn_pan(ha[,'x|y'])
%---
% pan axes
%
% See also fn_buttonmotion, fn_moveobject

% Thomas Deneux
% Copyright 2015-2017

if nargin<2, mode = 'xy'; end

ax0 = axis(ha);
p0 = get(ha,'currentpoint'); p0 = p0(1,1:2);
hf = fn_parentfigure(ha);
ptr = get(hf,'pointer');
set(hf,'pointer','hand')
fn_buttonmotion(@(u,e)pansub(ha,mode,ax0,p0))
set(hf,'pointer',ptr)

%--
function pansub(ha,mode,ax0,p0)

p = get(ha,'currentpoint'); p = p(1,1:2);
dp = p-p0;
ax = axis(ha);
if any(mode=='x')
    ax(1:2) = ax(1:2) - dp(1);
    set(ha,'xlim',ax(1:2))
end
if any(mode=='y')
    ax(3:4) = ax(3:4) - dp(2);
    set(ha,'ylim',ax(3:4))
end
        
