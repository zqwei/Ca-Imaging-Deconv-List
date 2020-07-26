function xpercent
% function xpercent
%---
% Add % sign to x ticks
%
% See also ypercent, xypercent, fn_ticks

set(gca,'xticklabel',fn_num2str(get(gca,'xtick'),'%i%%','cell'))
