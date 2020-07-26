function setColorbarSize(textLabel)

    ax     = gca;
    hColor = colorbar;
    axpos  = ax.Position;
        
    if nargin == 1
        ylabel(hColor, textLabel);
    end
        
    cPos            = hColor.Position;
    if axpos(1)+axpos(3) > 0.5
        hColorX = axpos(1)+axpos(3) + 0.11;
    else
        hColorX = axpos(1)+axpos(3);
    end
    hColor.Position = [hColorX cPos(2)+cPos(4)*0.25 cPos(3)*0.5 cPos(4)*0.5];
    cmin = get(ax,'CLim');
    cmax = cmin(2); cmin = cmin(1);
    set(hColor, 'YTick', [roundto(cmin), roundto(cmax)])