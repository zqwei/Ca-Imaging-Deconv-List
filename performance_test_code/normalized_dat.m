function dff = normalized_dat(dff)     
    dff = (dff - min(dff))/(max(dff)-min(dff));
end
