function setLabel(cmap, groupNames, fileName)

    figure;
    hold on
    for nColor = 1:length(groupNames)
        plot(0, nColor, 's', 'color', cmap(nColor,:), 'MarkerFaceColor',cmap(nColor,:),'MarkerSize', 8)
        text(1, nColor, groupNames{nColor})
    end
    xlim([0 10])
    hold off
    axis off
    setPrint(3, 0.5*length(groupNames), [fileName 'Label'])