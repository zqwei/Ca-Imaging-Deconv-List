function setColorbar(cmap, cmin, cmax, textLabel, fileName)

    figure;
    axis off
    colormap(cmap);
    caxis([roundto(cmin) roundto(cmax)]);
    setColorbarOnlySize(textLabel)
    setPrint(4, 6, [fileName 'Colorbar']);